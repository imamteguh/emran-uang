// ─────────────────────────────────────────────────────────────────────────────
// OCR Controller — Receipt Scanning with Google Gemini AI
// ─────────────────────────────────────────────────────────────────────────────

const { GoogleGenerativeAI } = require('@google/generative-ai');
const prisma = require('../config/prisma');
const { success, error } = require('../utils/apiResponse');

// ── Initialize Gemini ───────────────────────────────────────────────────────

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || '');

// ── Scan Receipt ────────────────────────────────────────────────────────────

async function scanReceipt(req, res) {
  const { image, mimeType } = req.body;

  // Validate input
  if (!image) {
    return error(res, 'image (base64) is required', 400);
  }

  const imageMimeType = mimeType || 'image/jpeg';

  try {
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

    // Build the prompt
    const prompt = `You are an expert receipt/invoice scanner for an Indonesian expense tracker app.

Analyze this receipt or invoice image carefully and extract the following information:

1. **amount**: The TOTAL amount paid (final total, after tax/discount). Return as a number only (no currency symbol, no thousands separator). If you see "Rp", "IDR", "$", or any currency prefix, remove it. For Indonesian receipts, amounts are typically whole numbers (no decimals).
2. **description**: A short, meaningful description of the purchase in the SAME LANGUAGE as the receipt (max 60 characters). Summarize what was bought, e.g. "Makan siang di Warteg", "Belanja bulanan Indomaret", "Kopi Starbucks".
3. **date**: The transaction date from the receipt in ISO 8601 format (YYYY-MM-DDTHH:mm:ss). If only a date is visible (no time), use T00:00:00. If no date is visible, return null.
4. **suggestedCategory**: Choose the BEST matching category from this list: [${categoryNames.join(', ')}]. If none match well, use "Other".

IMPORTANT RULES:
- Always return ONLY valid JSON, no markdown, no code fences, no explanation.
- If the image is not a receipt/invoice or is unreadable, return: {"error": "Could not read receipt"}
- For Indonesian receipts, look for keywords like "TOTAL", "GRAND TOTAL", "JUMLAH", "BAYAR", "TUNAI", "KEMBALIAN" to find the correct total.
- Choose the TOTAL PAID amount, not subtotal or individual items.

Return format:
{"amount": <number>, "description": "<string>", "date": "<ISO string or null>", "suggestedCategory": "<string>"}`;

    // Call Gemini Vision API
    const model = genAI.getGenerativeModel({ model: 'gemini-2.0-flash' });

    const result = await model.generateContent([
      prompt,
      {
        inlineData: {
          data: image,
          mimeType: imageMimeType,
        },
      },
    ]);

    const response = result.response;
    const text = response.text().trim();

    // Parse AI response
    let parsed;
    try {
      // Strip markdown code fences if present
      let cleanText = text;
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.replace(/^```(?:json)?\n?/, '').replace(/\n?```$/, '');
      }
      parsed = JSON.parse(cleanText);
    } catch (parseErr) {
      console.error('Gemini response parse error:', text);
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
            icon: matchedCategory.icon,
            color: matchedCategory.color,
          }
        : null,
      rawSuggestion: parsed.suggestedCategory || null,
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
