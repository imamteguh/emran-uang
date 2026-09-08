// ─────────────────────────────────────────────────────────────────────────────
// OCR Controller — Receipt Scanning with AI Vision (Gemini / OpenRouter / OpenAI)
// ─────────────────────────────────────────────────────────────────────────────

const { GoogleGenerativeAI } = require('@google/generative-ai');
const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// ── Helper: Robust JSON Extractor ──────────────────────────────────────────

function extractJsonFromText(rawText) {
  if (!rawText || typeof rawText !== 'string') return null;
  let text = rawText.trim();

  // Strip markdown code fences
  const codeBlockMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/i);
  if (codeBlockMatch) {
    text = codeBlockMatch[1].trim();
  }

  // Find outermost JSON object
  const firstBrace = text.indexOf('{');
  const lastBrace = text.lastIndexOf('}');
  if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
    text = text.substring(firstBrace, lastBrace + 1);
  }

  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

// ── Helper: OpenAI-Compatible Vision (OpenRouter / OpenAI) ─────────────────

async function callOpenAICompatibleVision({ apiKey, baseURL, model, image, mimeType, prompt }) {
  const start = Date.now();
  const url = `${baseURL.replace(/\/+$/, '')}/chat/completions`;
  const dataUrl = `data:${mimeType};base64,${image}`;
  console.log(`[OCR API] 🤖 Calling OpenAI-compatible vision: url=${url}, model=${model}, mimeType=${mimeType}`);

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

  const duration = Date.now() - start;

  if (!res.ok) {
    const errBody = await res.text();
    console.error(`[OCR API] ❌ AI Vision Provider error (${res.status}) in ${duration}ms: ${errBody}`);
    throw new Error(`AI Vision Provider error (${res.status}): ${errBody}`);
  }

  const json = await res.json();
  const text = json.choices?.[0]?.message?.content;
  if (!text) {
    console.error(`[OCR API] ❌ No content in AI Vision Provider response:`, json);
    throw new Error('No content returned from AI Vision Provider');
  }
  console.log(`[OCR API] 📥 AI response received in ${duration}ms (${text.length} chars)`);
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
    const start = Date.now();
    try {
      console.log(`[OCR API] 🤖 Calling Gemini model "${modelName}" (baseUrl=${requestOptions.baseUrl || 'default'})...`);
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
      const duration = Date.now() - start;
      const response = result.response;
      if (response) {
        const text = response.text().trim();
        console.log(`[OCR API] 📥 Gemini model "${modelName}" succeeded in ${duration}ms (${text.length} chars)`);
        return text;
      }
    } catch (err) {
      lastError = err;
      console.warn(`[OCR API] ⚠️ Gemini model "${modelName}" failed:`, err.message || err);
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
  const scanStart = Date.now();
  const { image, mimeType, walletId } = req.body;

  // Validate input
  if (!image) {
    console.warn('[OCR API] ⚠️ Rejected request: missing image base64');
    return error(res, 'image (base64) is required', 400);
  }

  const imageMimeType = mimeType || 'image/jpeg';
  const approxSizeKb = Math.round((image.length * 0.75) / 1024);
  console.log(`[OCR API] 📥 Received scan request: user=${req.user?.id || 'anon'}, walletId=${walletId || 'none'}, mimeType=${imageMimeType}, size=~${approxSizeKb} KB`);

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
    console.log(`[OCR API] 📋 Found ${categories.length} available categories for matching: [${categoryNames.slice(0, 8).join(', ')}${categoryNames.length > 8 ? '...' : ''}]`);

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
    console.log(`[OCR API] ⚙️ Active provider config: "${provider || 'gemini (default)'}"`);

    // 1. Direct OpenRouter if specified
    if (provider === 'openrouter' || (!provider && process.env.OPENROUTER_API_KEY && !process.env.GEMINI_API_KEY)) {
      const model = process.env.OPENROUTER_MODEL || 'google/gemini-2.5-flash';
      console.log(`[OCR API] 🚀 Routing to OpenRouter Vision (model: ${model})...`);
      text = await callOpenAICompatibleVision({
        apiKey: process.env.OPENROUTER_API_KEY,
        baseURL: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
        model: model,
        image,
        mimeType: imageMimeType,
        prompt,
      });
    }
    // 2. Direct OpenAI if specified
    else if (provider === 'openai' || (!provider && process.env.OPENAI_API_KEY && !process.env.GEMINI_API_KEY)) {
      const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
      console.log(`[OCR API] 🚀 Routing to OpenAI Vision (model: ${model})...`);
      text = await callOpenAICompatibleVision({
        apiKey: process.env.OPENAI_API_KEY,
        baseURL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
        model: model,
        image,
        mimeType: imageMimeType,
        prompt,
      });
    }
    // 3. Default: Gemini Vision API (with automatic fallback to OpenRouter/OpenAI if location blocked)
    else {
      try {
        console.log('[OCR API] 🚀 Routing to Google Gemini Vision API...');
        text = await callGeminiVision({
          image,
          mimeType: imageMimeType,
          prompt,
        });
      } catch (geminiErr) {
        console.warn('[OCR API] ⚠️ Gemini Vision call failed:', geminiErr.message || geminiErr);

        if (process.env.OPENROUTER_API_KEY) {
          console.warn('[OCR API] 🔄 Falling back to OpenRouter Vision API...');
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
            console.error('[OCR API] ❌ OpenRouter fallback also failed:', openRouterErr.message || openRouterErr);
            throw geminiErr;
          }
        } else if (process.env.OPENAI_API_KEY) {
          console.warn('[OCR API] 🔄 Falling back to OpenAI Vision API...');
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
            console.error('[OCR API] ❌ OpenAI fallback also failed:', openAiErr.message || openAiErr);
            throw geminiErr;
          }
        } else {
          const isGeoBlocked =
            geminiErr.message?.includes('location is not supported') ||
            geminiErr.status === 400;

          if (isGeoBlocked) {
            console.error('[OCR API] ❌ Gemini API blocked: Server location is not supported by Google AI.');
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
    console.log(`[OCR API] 📄 Raw AI output:\n${text}`);
    let parsed = extractJsonFromText(text);
    if (!parsed) {
      console.error('[OCR API] ❌ Failed to parse JSON from AI response text:', text);
      return error(res, 'AI could not parse the receipt. Please try again with a clearer image.', 422);
    }

    // Check for AI-reported error
    if (parsed.error) {
      console.warn(`[OCR API] ⚠️ AI reported unreadable receipt: ${parsed.error}`);
      return error(res, parsed.error, 422);
    }

    // Sanitize and validate parsed amount
    let amount = parsed.amount;
    if (typeof amount === 'string') {
      let cleanAmount = amount.replace(/[^0-9.,]/g, '').trim();
      if (cleanAmount.includes(',') && cleanAmount.includes('.')) {
        if (cleanAmount.lastIndexOf(',') > cleanAmount.lastIndexOf('.')) {
          // Format like 50.000,00
          cleanAmount = cleanAmount.replace(/\./g, '').replace(',', '.');
        } else {
          // Format like 50,000.00
          cleanAmount = cleanAmount.replace(/,/g, '');
        }
      } else if (cleanAmount.includes(',')) {
        const parts = cleanAmount.split(',');
        if (parts[1] && parts[1].length === 2) {
          cleanAmount = cleanAmount.replace(',', '.');
        } else {
          cleanAmount = cleanAmount.replace(/,/g, '');
        }
      }
      amount = parseFloat(cleanAmount);
    }

    if (!amount || typeof amount !== 'number' || isNaN(amount) || amount <= 0) {
      console.warn(`[OCR API] ⚠️ Invalid extracted amount: "${parsed.amount}"`);
      return error(res, 'Could not extract a valid amount from the receipt.', 422);
    }
    parsed.amount = amount;

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

    console.log(`[OCR API] 🏷️ Matched category: "${parsed.suggestedCategory}" -> ${matchedCategory ? `"${matchedCategory.name}" (${matchedCategory.id})` : 'null'}`);
    console.log(`[OCR API] ✅ Receipt parsed successfully in ${Date.now() - scanStart}ms: amount=${parsed.amount}, date=${parsed.date}, desc="${parsed.description}"`);

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
    console.error(`[OCR API] ❌ OCR scan error (${Date.now() - scanStart}ms):`, err);

    if (err.message?.includes('API_KEY')) {
      return error(res, 'AI service is not configured. Please contact support.', 500);
    }

    return error(res, 'Failed to scan receipt. Please try again.', 500);
  }
}

module.exports = {
  scanReceipt,
};
