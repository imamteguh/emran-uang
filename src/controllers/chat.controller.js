// ─────────────────────────────────────────────────────────────────────────────
// Chat Controller — AI-Powered Natural Language Transaction Input
// ─────────────────────────────────────────────────────────────────────────────
// Allows users to save transactions by sending natural language messages
// like "makan siang 25k" — AI parses the message, matches a category,
// and saves the expense directly to the database.
// ─────────────────────────────────────────────────────────────────────────────

const { GoogleGenerativeAI } = require('@google/generative-ai');
const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');
const { notifyGroupMembers } = require('../utils/notification.helper');

// ── Initialize Gemini ───────────────────────────────────────────────────────

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

  return JSON.parse(text);
}

// ── Helper: Timezone Offset String (+07:00, etc.) ──────────────────────────

function getTimezoneOffsetString(timeZone) {
  try {
    const now = new Date();
    const tzDate = new Date(now.toLocaleString('en-US', { timeZone }));
    const diff = tzDate.getTime() - new Date(now.toLocaleString('en-US', { timeZone: 'UTC' })).getTime();
    const totalMinutes = Math.round(diff / (60 * 1000));
    const sign = totalMinutes >= 0 ? '+' : '-';
    const absMinutes = Math.abs(totalMinutes);
    const hours = String(Math.floor(absMinutes / 60)).padStart(2, '0');
    const minutes = String(absMinutes % 60).padStart(2, '0');
    return `${sign}${hours}:${minutes}`;
  } catch {
    return '+07:00';
  }
}

// ── Helper: OpenAI-Compatible Text Chat ─────────────────────────────────────

async function callOpenAICompatibleChat({ apiKey, baseURL, model, prompt }) {
  const url = `${baseURL.replace(/\/+$/, '')}/chat/completions`;

  const res = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
      'HTTP-Referer': 'https://emran-uang.app',
      'X-Title': 'Emran Uang AI Chat',
    },
    body: JSON.stringify({
      model: model,
      messages: [
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.1,
      max_tokens: 500,
    }),
  });

  if (!res.ok) {
    const errBody = await res.text();
    throw new Error(`AI Provider error (${res.status}): ${errBody}`);
  }

  const json = await res.json();
  const text = json.choices?.[0]?.message?.content;
  if (!text) {
    throw new Error('No content returned from AI Provider');
  }
  return text.trim();
}

// ── Helper: Gemini Text Chat ────────────────────────────────────────────────

async function callGeminiChat({ prompt }) {
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
      const result = await model.generateContent([prompt]);
      const response = result.response;
      if (response) {
        return response.text().trim();
      }
    } catch (err) {
      lastError = err;
      console.warn(`Gemini model "${modelName}" failed:`, err.message || err);
      if (err.status === 404 || err.message?.includes('not found') || err.message?.includes('no longer available')) {
        continue;
      }
      throw err;
    }
  }

  throw lastError || new Error('Failed to generate content with available Gemini models');
}

// ── Process Chat Transaction ────────────────────────────────────────────────

async function chatTransaction(req, res) {
  const { message, walletId, timezone } = req.body;

  // Validate input
  if (!message || typeof message !== 'string' || message.trim().length === 0) {
    return error(res, 'message is required', 400);
  }

  const trimmedMessage = message.trim();

  if (trimmedMessage.length > 500) {
    return error(res, 'Message too long (max 500 characters)', 400);
  }

  try {
    // ── Resolve wallet ──────────────────────────────────────────────────
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

    // Fallback 1: use user's personal wallet
    if (!targetWallet) {
      targetWallet = await prisma.wallet.findFirst({
        where: {
          userId: req.user.id,
          type: 'PERSONAL',
        },
      });
    }

    // Fallback 2: any accessible wallet
    if (!targetWallet) {
      targetWallet = await prisma.wallet.findFirst({
        where: {
          OR: [
            { userId: req.user.id },
            {
              group: {
                members: {
                  some: { userId: req.user.id },
                },
              },
            },
          ],
        },
      });
    }

    if (!targetWallet) {
      return error(res, 'No wallet found. Please create a wallet first.', 404);
    }

    // ── Fetch user's categories for AI matching ─────────────────────────
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

    const categoryList = categories.map((c) => `"${c.name}"`).join(', ');
    const walletCurrency = targetWallet.currency || 'IDR';

    // ── Compute timezone-aware dates & current time ─────────────────────
    const userTimezone = timezone || req.headers['x-timezone'] || 'Asia/Jakarta';
    const tzOffset = getTimezoneOffsetString(userTimezone);

    let todayStr;
    let yesterdayStr;
    let currentTimeStr;
    const now = new Date();

    try {
      todayStr = new Intl.DateTimeFormat('en-CA', { timeZone: userTimezone }).format(now);
      const yesterdayDate = new Date(now.getTime() - 24 * 60 * 60 * 1000);
      yesterdayStr = new Intl.DateTimeFormat('en-CA', { timeZone: userTimezone }).format(yesterdayDate);
      currentTimeStr = new Intl.DateTimeFormat('en-GB', {
        timeZone: userTimezone,
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        hour12: false,
      }).format(now);
    } catch {
      todayStr = now.toISOString().split('T')[0];
      const yDate = new Date();
      yDate.setDate(yDate.getDate() - 1);
      yesterdayStr = yDate.toISOString().split('T')[0];
      currentTimeStr = now.toTimeString().split(' ')[0];
    }

    // ── Build AI prompt ─────────────────────────────────────────────────
    const prompt = `You are a smart expense parsing assistant for an Indonesian expense tracker app.
The user's currency is ${walletCurrency}.
Today's date: ${todayStr}
Current time right now: ${currentTimeStr}
User's timezone: ${userTimezone}

Parse the following user message and extract expense information.

User message: "${trimmedMessage}"

PARSING RULES:
1. **Amount**: Parse Indonesian shorthand numbers and formats:
   - "25k" or "25K" → 25000
   - "1.5jt" or "1,5jt" or "1.5 juta" → 1500000
   - "500rb" or "500 ribu" → 500000
   - "25ribu" → 25000
   - "25000" → 25000
   - "25.000" → 25000 (Indonesian thousands separator)
   - "sepuluh ribu" → 10000, "lima puluh ribu" → 50000
   - If no valid expense amount is found, return {"error": "Tidak bisa menentukan jumlah dari pesan ini. Coba sertakan nominal, misalnya: 'makan siang 25k'"}

2. **Description**: Extract a concise, clear description (max 60 chars) in the same language. Capitalize the first letter. E.g. "Makan siang", "Kopi Kenangan", "Bensin Pertamax", "Beli baju". Do NOT include the amount in the description.

3. **Date & Time (CRITICAL TIME RULES)**:
   - TIME/JAM EXTRACTION:
     * Check if the user message specifies an hour or time of day:
       - Explicit hours:
         * "jam 10" / "jam 10 pagi" → 10:00:00
         * "jam 1 siang" / "jam 13" / "jam 13.00" / "13:00" → 13:00:00
         * "jam 2 siang" / "jam 14" / "14.30" → 14:00:00 / 14:30:00
         * "jam 8 malam" / "jam 20" / "20:00" → 20:00:00
         * "pukul 15:45" → 15:45:00
         * "jam 10.30" → 10:30:00
       - Contextual approximate times (when no explicit hour given):
         * "tadi pagi" (without explicit hour) → 08:00:00
         * "tadi siang" (without explicit hour) → 12:00:00
         * "tadi sore" (without explicit hour) → 16:00:00
         * "tadi malam" (without explicit hour) → 20:00:00
     * CRITICAL: IF NO TIME OR HOUR IS MENTIONED IN THE MESSAGE:
       YOU MUST USE THE CURRENT TIME RIGHT NOW: ${currentTimeStr}!
       Do NOT default to 00:00:00! Always set the time to ${currentTimeStr}.

   - DATE DETERMINATION:
     * Default to today (${todayStr}) unless specified:
       - "kemarin" / "yesterday" → ${yesterdayStr}
       - Specific date like "tanggal 5" → YYYY-MM-DD
     * If "kemarin" is specified with NO hour mentioned, combine ${yesterdayStr} with the CURRENT TIME ${currentTimeStr}.

   - FINAL FORMAT: Return "date" as ISO 8601 string: "YYYY-MM-DDTHH:mm:ss".

4. **Type**: Default to "NON_ROUTINE".
   - If keywords like "rutin", "bulanan", "langganan", "subscription", "cicilan", "tagihan" → "ROUTINE"

5. **Category**: Choose the BEST matching category from available categories: [${categoryList}].
   - Match by Indonesian context:
     * makan, minum, kopi, nasi, sate, bakso, warteg, resto, cafe, jajan, snack, gofood, grabfood → "Food & Drinks" or "Food"
     * bensin, pertamina, pertalite, pertamax, gojek, grab, ojek, parkir, tol, kereta, bus, servis, bengkel → "Transport"
     * indomaret, alfamart, supermarket, pasar, belanja sayur, kebutuhan dapur, sembako → "Groceries"
     * pulsa, paket data, pln, token, listrik, pdam, air, wifi, internet, indihome → "Utilities" or "Bills"
     * netflix, spotify, bioskop, film, game, steam → "Entertainment" or "Subscriptions"
     * baju, celana, sepatu, shopee, tokopedia, lazada, mall → "Shopping"
     * obat, apotek, dokter, rs, vitamin → "Healthcare" or "Health"
     * sewa, kos, kontrakan, rumah → "Housing"
     * spp, kursus, buku, kuliah, sekolah → "Education"
   - If none match well, use "Other"

6. **aiMessage**: Create a friendly confirmation message in Indonesian:
   - If a specific hour was in the user message:
     "✅ <Description> Rp <Amount formatted> (jam <HH:mm>) — kategori <Category>"
   - If no specific hour was mentioned:
     "✅ <Description> Rp <Amount formatted> — kategori <Category>"

IMPORTANT: Return ONLY valid JSON, no markdown code fences, no extra text.
If the message is clearly NOT an expense record, return:
{"error": "Maaf, saya tidak bisa memahami pesan ini sebagai transaksi. Coba format: 'makan siang 25k'"}

Return format:
{"amount": <number>, "description": "<string>", "date": "<ISO string YYYY-MM-DDTHH:mm:ss>", "type": "ROUTINE" or "NON_ROUTINE", "suggestedCategory": "<string>", "aiMessage": "<string>"}`;

    // ── Call AI ──────────────────────────────────────────────────────────
    let text;
    const provider = (process.env.AI_PROVIDER || '').toLowerCase();

    if (provider === 'openrouter' || (!provider && process.env.OPENROUTER_API_KEY && !process.env.GEMINI_API_KEY)) {
      text = await callOpenAICompatibleChat({
        apiKey: process.env.OPENROUTER_API_KEY,
        baseURL: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
        model: process.env.OPENROUTER_MODEL || 'google/gemini-2.5-flash',
        prompt,
      });
    } else if (provider === 'openai' || (!provider && process.env.OPENAI_API_KEY && !process.env.GEMINI_API_KEY)) {
      text = await callOpenAICompatibleChat({
        apiKey: process.env.OPENAI_API_KEY,
        baseURL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        prompt,
      });
    } else {
      try {
        text = await callGeminiChat({ prompt });
      } catch (geminiErr) {
        console.warn('[Chat] Gemini call failed:', geminiErr.message || geminiErr);

        if (process.env.OPENROUTER_API_KEY) {
          console.warn('[Chat] Falling back to OpenRouter...');
          try {
            text = await callOpenAICompatibleChat({
              apiKey: process.env.OPENROUTER_API_KEY,
              baseURL: process.env.OPENROUTER_BASE_URL || 'https://openrouter.ai/api/v1',
              model: process.env.OPENROUTER_MODEL || 'google/gemini-2.5-flash',
              prompt,
            });
          } catch (openRouterErr) {
            console.error('[Chat] OpenRouter fallback also failed:', openRouterErr.message || openRouterErr);
            throw geminiErr;
          }
        } else if (process.env.OPENAI_API_KEY) {
          console.warn('[Chat] Falling back to OpenAI...');
          try {
            text = await callOpenAICompatibleChat({
              apiKey: process.env.OPENAI_API_KEY,
              baseURL: process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1',
              model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
              prompt,
            });
          } catch (openAiErr) {
            console.error('[Chat] OpenAI fallback also failed:', openAiErr.message || openAiErr);
            throw geminiErr;
          }
        } else {
          const isGeoBlocked =
            geminiErr.message?.includes('location is not supported') ||
            geminiErr.status === 400;

          if (isGeoBlocked) {
            return error(
              res,
              'Google AI tidak mendukung lokasi server ini. Silakan gunakan OPENROUTER_API_KEY di file .env.',
              422
            );
          }
          throw geminiErr;
        }
      }
    }

    // ── Parse AI response ───────────────────────────────────────────────
    let parsed;
    try {
      parsed = extractJsonFromText(text);
      if (!parsed || typeof parsed !== 'object') {
        throw new Error('Failed to extract JSON object');
      }
    } catch (parseErr) {
      console.error('[Chat] AI response parse error. Raw text:', text);
      return error(res, 'AI tidak bisa memahami pesan tersebut. Coba format: "makan siang 25k"', 422);
    }

    // Check for AI-reported error
    if (parsed.error) {
      return success(res, {
        saved: false,
        aiMessage: parsed.error,
        expense: null,
      }, parsed.error);
    }

    // Validate parsed amount (support number and string)
    const amountNum = Number(parsed.amount);
    if (isNaN(amountNum) || amountNum <= 0) {
      return success(res, {
        saved: false,
        aiMessage: 'Tidak bisa menentukan jumlah dari pesan ini. Coba sertakan nominal, misalnya: "makan siang 25k"',
        expense: null,
      }, 'Could not determine amount');
    }

    // ── Match category ──────────────────────────────────────────────────
    let matchedCategory = null;
    if (parsed.suggestedCategory) {
      const suggested = parsed.suggestedCategory.toLowerCase().trim();
      matchedCategory = categories.find(
        (c) => c.name.toLowerCase() === suggested
      );

      // Fuzzy match
      if (!matchedCategory) {
        matchedCategory = categories.find(
          (c) =>
            c.name.toLowerCase().includes(suggested) ||
            suggested.includes(c.name.toLowerCase())
        );
      }

      // Fallback to "Other"
      if (!matchedCategory) {
        matchedCategory = categories.find(
          (c) => c.name.toLowerCase() === 'other'
        );
      }
    }

    // Ultimate fallback: use first available category
    if (!matchedCategory && categories.length > 0) {
      matchedCategory = categories.find((c) => c.name.toLowerCase() === 'other') || categories[0];
    }

    if (!matchedCategory) {
      return error(res, 'No categories available. Please create a category first.', 404);
    }

    // ── Resolve exact transaction date with timezone offset ────────────
    let expenseDate = new Date();
    if (parsed.date) {
      let dateString = String(parsed.date).trim();
      if (!dateString.endsWith('Z') && !/[+-]\d{2}:\d{2}$/.test(dateString)) {
        dateString += tzOffset;
      }
      const parsedD = new Date(dateString);
      if (!isNaN(parsedD.getTime())) {
        expenseDate = parsedD;
      }
    }

    // ── Save expense to database ────────────────────────────────────────
    const expense = await prisma.expense.create({
      data: {
        amount: amountNum,
        description: parsed.description || trimmedMessage,
        date: expenseDate,
        type: parsed.type === 'ROUTINE' ? 'ROUTINE' : 'NON_ROUTINE',
        userId: req.user.id,
        walletId: targetWallet.id,
        categoryId: matchedCategory.id,
      },
      include: {
        category: { select: { id: true, name: true, icon: true, color: true } },
        user: { select: { id: true, displayName: true, avatarUrl: true } },
      },
    });

    // ── Notify group members if shared wallet ───────────────────────────
    if (targetWallet.type === 'SHARED' && targetWallet.groupId) {
      const group = await prisma.sharedGroup.findUnique({
        where: { id: targetWallet.groupId },
        select: { name: true },
      });
      await notifyGroupMembers(prisma, targetWallet.groupId, [req.user.id], {
        type: 'GROUP_EXPENSE_ADDED',
        title: 'New Expense',
        body: `${req.user.displayName || 'Member'} added an expense of Rp ${amountNum.toLocaleString('id-ID')}${parsed.description ? ' — ' + parsed.description : ''} in "${group?.name || 'shared group'}"`,
        metadata: {
          groupId: targetWallet.groupId,
          expenseId: expense.id,
          amount: amountNum,
        },
      });
    }

    // ── Return response ─────────────────────────────────────────────────
    const aiMessage = parsed.aiMessage ||
      `✅ Transaksi disimpan: ${parsed.description || trimmedMessage} — Rp ${amountNum.toLocaleString('id-ID')} (${matchedCategory.name})`;

    return success(res, {
      saved: true,
      aiMessage,
      expense,
    }, 'Transaction saved via AI chat');

  } catch (err) {
    console.error('[Chat] Transaction error:', err);

    if (err.message?.includes('API_KEY')) {
      return error(res, 'AI service is not configured. Please contact support.', 500);
    }

    return error(res, 'Gagal memproses pesan. Silakan coba lagi.', 500);
  }
}

module.exports = {
  chatTransaction,
};
