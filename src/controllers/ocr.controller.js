// ─────────────────────────────────────────────────────────────────────────────
// OCR Controller — Receipt Scanning with AI Vision (Gemini / OpenRouter / OpenAI)
// ─────────────────────────────────────────────────────────────────────────────

const { GoogleGenerativeAI } = require('@google/generative-ai');
const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');

// ── Initialize Gemini ───────────────────────────────────────────────────────

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// ── Helper: OpenAI-Compatible Vision (OpenRouter / OpenAI) ─────────────────

async function callOpenAICompatibleVision({ apiKey, baseURL, model, image, mimeType, prompt }) {
  const url = `${baseURL.replace(/\/+$/, '')}/chat/completions`;
  const dataUrl = `data:${mimeType};base64,${image}`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'HTTP-Referer': 'https://emran-uang.app',
      'X-Title': 'Emran Uang Receipt Scanner',
    },
    body: JSON.stringify({
      model: model,
      messages: [
        {
          role: 'user',
          content: [
            { type: 'text', text: prompt },
            {
              type: 'image_url',
              image_url: {
                url: dataUrl,
              },
            },
          ],
        },
      ],
      temperature: 0.1,
      max_tokens: 600,
    }),
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`AI Vision Provider error (${res.status}): ${errBody}`);
  }

  const json = await res.json();
  const text = json.choices?.[0]?.message?.content;
  if (!text) {
    throw new Error('No content returned from AI Vision Provider');
  }
  return text.trim();
}

// ── Helper: Gemini Vision API ───────────────────────────────────────────────

async function callGeminiVision({ image, mimeType, prompt }) {
  const candidateModels = [
    process.env.GEMINI_MODEL,
    'gemini-3.6-flash',
    'gemini-2.5-flash',
    'gemini-1.5-flash',
  ].filter(Boolean);
  const modelsToTry = [...new Set(candidateModels)];

  const requestOptions = {};
  if (process.env.GEMINI_BASE_URL) {
    requestOptions.baseUrl = process.env.GEMINI_BASE_URL.replace(/\/+$/, '');
  }

  let lastError;

  for (const modelName of modelsToTry) {
    try {
      const model = genAI.getGenerativeModel({ model: modelName }, requestOptions);
      const result = await model.generateContent([
        prompt,
        {
          inlineData: {
            data: image,
            mimeType: mimeType,
          },
        },
      ]);
      const response = result.response;
      if (response) {
        return response.text().trim();
      }
    } catch (err) {
      lastError = err;
      console.warn(`Gemini model "${modelName}" failed:`, err.message || err);
      // If 404 (model deprecated / not found), continue to next fallback
      if (err.status === 404 || err.message?.includes('not found') || err.message?.includes('no longer available')) {
        continue;
      }
      // If user location not supported or other errors, rethrow so caller can handle
      throw err;
    }
  }

  throw lastError || new Error('Failed to generate content with available Gemini models');
}

// ── Scan Receipt ────────────────────────────────────────────────────────────

async function scanReceipt(req, res) {
  const { image, mimeType, walletId } = req.body;

  // Validate input
  if (!image) {
    return error(res, 'image (base64) is required', 400);
  }

  const imageMimeType = mimeType || 'image/jpeg';

  try {
    // Optional wallet context (supports both personal and shared/group wallets)
    let targetWallet = null;
    if (walletId) {
      targetWallet = await prisma.wallet.findUnique({
        where: { id: walletId },
        include: {
          group: {
            include: {
              members: {
                where: { userId: req.user.id },
              },
            },
          },
        },
      });

      // Verify user access
      if (targetWallet) {
        if (targetWallet.type === 'SHARED') {
          const isMember = targetWallet.group?.members?.length > 0;
          if (!isMember) targetWallet = null;
        } else if (targetWallet.userId !== req.user.id) {
          targetWallet = null;
        }
      }
    }

    // Fetch user's categories for AI matching
    const categories = await prisma.category.findMany({
      where: {
        OR: [
          { userId: req.user.id },
          { isDefault: true },
        ],
        isActive: true,
      },
      select: { id: true, name: true, icon: true, color: true },
    });

    const categoryNames = categories.map((c) => c.name);
    const walletCurrency = targetWallet?.currency || 'IDR';
    const isShared = targetWallet?.type === 'SHARED';
    const walletContext = targetWallet
      ? `This receipt is for ${isShared ? `shared group wallet "${targetWallet.name}"` : `personal wallet "${targetWallet.name}"`} in currency ${walletCurrency}.`
      : `The currency is ${walletCurrency}.`;

    // Build the prompt
    const prompt = `You are an expert receipt/invoice scanner for an expense tracker app.
${walletContext}

Analyze this receipt or invoice image carefully and extract the following information:

1. **amount**: The TOTAL amount paid (final total, after tax/discount). Return as a number only (no currency symbol, no thousands separator). If currency is IDR, amounts are typically whole numbers without decimals (e.g. 50000). If currency is USD/SGD/EUR, extract decimal values if present (e.g. 24.50).
2. **description**: A short, meaningful description of the purchase in the SAME LANGUAGE as the receipt (max 60 characters). Summarize what was bought, e.g. "Makan siang di Warteg", "Belanja bulanan Indomaret", "Kopi Starbucks".
3. **date**: The transaction date from the receipt in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If only a date is visible (no time), use T00:00:00. If no date is visible, return null.
4. **suggestedCategory**: Choose the BEST matching category from this list: [${categoryNames.join(', ')}]. If none match well, use "Other".

IMPORTANT RULES:
- Always return ONLY valid JSON, no markdown, no code fences, no explanation.
- If the image is not a receipt/invoice or is unreadable, return: {"error": "Could not read receipt"}
- Look for keywords like "TOTAL", "GRAND TOTAL", "JUMLAH", "BAYAR", "TUNAI", "KEMBALIAN" to find the correct total.
- Choose the TOTAL PAID amount, not subtotal or individual items.

Return format:
{"amount": <number>, "description": "<string>", "date": "<ISO string or null>", "suggestedCategory": "<string>"}`;

    let text;
    const provider = (process.env.AI_PROVIDER || '').toLowerCase();

    // 1. Direct OpenRouter if specified
    if (provider === 'openrouter' || (!provider && process.env.OPENROUTER_API_KEY && !process.env.GEMINI_API_KEY)) {
      text = await callOpenAICompatibleVision({
        apiKey: process.env.OPENROUTER_API_KEY,
        baseURL: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
        model: process.env.OPENROUTER_MODEL || 'google/gemini-2.5-flash',
        image,
        mimeType: imageMimeType,
        prompt,
      });
    }
    // 2. Direct OpenAI if specified
    else if (provider === 'openai' || (!provider && process.env.OPENAI_API_KEY && !process.env.GEMINI_API_KEY)) {
      text = await callOpenAICompatibleVision({
        apiKey: process.env.OPENAI_API_KEY,
        baseURL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        image,
        mimeType: imageMimeType,
        prompt,
      });
    }
    // 3. Default: Gemini Vision API (with automatic fallback to OpenRouter/OpenAI if location blocked)
    else {
      try {
        text = await callGeminiVision({
          image,
          mimeType: imageMimeType,
          prompt,
        });
      } catch (geminiErr) {
        console.warn('[OCR] Gemini Vision call failed:', geminiErr.message || geminiErr);

        if (process.env.OPENROUTER_API_KEY) {
          console.warn('[OCR] Falling back to OpenRouter Vision API...');
          try {
            text = await callOpenAICompatibleVision({
              apiKey: process.env.OPENROUTER_API_KEY,
              baseURL: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
              model: process.env.OPENROUTER_MODEL || 'google/gemini-2.5-flash',
              image,
              mimeType: imageMimeType,
              prompt,
            });
          } catch (openRouterErr) {
            console.error('[OCR] OpenRouter fallback also failed:', openRouterErr.message || openRouterErr);
            throw geminiErr;
          }
        } else if (process.env.OPENAI_API_KEY) {
          console.warn('[OCR] Falling back to OpenAI Vision API...');
          try {
            text = await callOpenAICompatibleVision({
              apiKey: process.env.OPENAI_API_KEY,
              baseURL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
              model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
              image,
              mimeType: imageMimeType,
              prompt,
            });
          } catch (openAiErr) {
            console.error('[OCR] OpenAI fallback also failed:', openAiErr.message || openAiErr);
            throw geminiErr;
          }
        } else {
          const isGeoBlocked =
            geminiErr.message?.includes('location is not supported') ||
            geminiErr.status === 400;

          if (isGeoBlocked) {
            console.error('[OCR] Gemini API blocked: Server location is not supported by Google AI.');
            return error(
              res,
              'Google AI tidak mendukung lokasi server ini (User location is not supported). Silakan gunakan GEMINI_BASE_URL (Cloudflare Worker proxy) atau OPENROUTER_API_KEY di file .env server Anda.',
              422
            );
          }
          throw geminiErr;
        }
      }
    }

    // Parse AI response
    let parsed;
    try {
      let cleanText = text;
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
      }
      parsed = JSON.parse(cleanText);
    } catch (parseErr) {
      console.error('AI response parse error:', text);
      return error(res, 'AI could not parse the receipt. Please try again with a clearer image.', 422);
    }

    // Check for AI-reported error
    if (parsed.error) {
      return error(res, parsed.error, 422);
    }

    // Validate parsed amount
    if (!parsed.amount || typeof parsed.amount !== 'number' || parsed.amount <= 0) {
      return error(res, 'Could not extract a valid amount from the receipt.', 422);
    }

    // Match suggested category with user's categories
    let matchedCategory = null;
    if (parsed.suggestedCategory) {
      const suggested = parsed.suggestedCategory.toLowerCase().trim();
      matchedCategory = categories.find(
        (c) => c.name.toLowerCase() === suggested
      );

      // Fuzzy match: try partial match if exact match fails
      if (!matchedCategory) {
        matchedCategory = categories.find(
          (c) =>
            c.name.toLowerCase().includes(suggested) ||
            suggested.includes(c.name.toLowerCase())
        );
      }

      // Fallback to "Other" category
      if (!matchedCategory) {
        matchedCategory = categories.find(
          (c) => c.name.toLowerCase() === 'other'
        );
      }
    }

    // Build response
    const ocrResult = {
      amount: parsed.amount,
      description: parsed.description || null,
      date: parsed.date || null,
      suggestedCategory: matchedCategory
        ? {
            id: matchedCategory.id,
            name: matchedCategory.name,
            icon: matchedCategory.icon || 'category',
            color: matchedCategory.color || '#4F46E5',
          }
        : null,
      rawSuggestion: parsed.suggestedCategory || null,
      walletId: targetWallet ? targetWallet.id : null,
      walletCurrency: walletCurrency,
    };

    return success(res, ocrResult, 'Receipt scanned successfully');
  } catch (err) {
    console.error('OCR scan error:', err);

    if (err.message?.includes('API_KEY')) {
      return error(res, 'AI service is not configured. Please contact support.', 500);
    }

    return error(res, 'Failed to scan receipt. Please try again.', 500);
  }
}

module.exports = {
  scanReceipt,
};
