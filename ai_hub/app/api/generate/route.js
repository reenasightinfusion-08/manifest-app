import { NextResponse } from 'next/server';
import { Groq } from 'groq-sdk';
import { GoogleGenerativeAI } from '@google/generative-ai';

// ── Default config (edit hub_settings.json locally, or set ACTIVE_PROVIDER env var on Vercel) ──
const DEFAULT_SETTINGS = {
  active_provider: 'groq',
  providers: {
    groq:   { name: 'Groq AI (GPT-OSS 120B)', model: 'openai/gpt-oss-120b' },
    gemini: { name: 'Google Gemini',        model: 'gemini-1.5-flash' },
    openai: { name: 'OpenAI ChatGPT',        model: 'gpt-4o' },
  }
};

function getSettings() {
  // Override active provider via Vercel env var so you can switch without redeploying
  return {
    ...DEFAULT_SETTINGS,
    active_provider: process.env.ACTIVE_PROVIDER || DEFAULT_SETTINGS.active_provider,
  };
}

const VISION_MODEL = process.env.GEMINI_VISION_MODEL || 'gemini-2.5-flash';

// Models sometimes wrap JSON in ```json fences even in JSON mode.
function parseJson(text) {
  return JSON.parse(text.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, ''));
}

// files: [{ mimeType: 'image/jpeg' | 'application/pdf' | ..., data: <base64> }]
async function readFiles({ prompt, systemPrompt, format, files }) {
  const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
  const model = genAI.getGenerativeModel({
    model: VISION_MODEL,
    systemInstruction: systemPrompt || undefined,
  });
  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [
        { text: prompt || 'Read the attached file.' },
        ...files.map((f) => ({ inlineData: { mimeType: f.mimeType, data: f.data } })),
      ],
    }],
    generationConfig: {
      maxOutputTokens: 8000,
      temperature: 0,
      ...(format === 'json' && { responseMimeType: 'application/json' }),
    },
  });
  const text = result.response.text();
  return { success: true, provider: 'gemini', data: format === 'json' ? parseJson(text) : text };
}

export async function POST(req) {
  try {
    const { prompt, systemPrompt, format, files } = await req.json();
    const settings = getSettings();
    const activeProvider = settings.active_provider;

    // Photos and PDFs: Groq's chat model only takes text, so any request that carries files is read by Gemini.
    if (Array.isArray(files) && files.length > 0) {
      return NextResponse.json(await readFiles({ prompt, systemPrompt, format, files }));
    }

    console.log(`[AI HUB] Routing request to: ${activeProvider}`);

    if (activeProvider === 'groq') {
      const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
      const response = await groq.chat.completions.create({
        model: settings.providers.groq.model,
        messages: [
          { role: 'system', content: systemPrompt || 'You are a helpful assistant.' },
          { role: 'user', content: prompt }
        ],
        response_format: format === 'json' ? { type: 'json_object' } : undefined,
        // Without an explicit cap, the SDK/model default can be small enough
        // to silently truncate multi-section JSON responses (e.g. a 3-7
        // pillar manifestation plan), which showed up as suspiciously short,
        // over-compressed pillar text. Give it real headroom.
        max_tokens: 8000,
        temperature: 0.8,
      });
      return NextResponse.json({ 
        success: true, 
        provider: 'groq',
        data: format === 'json' ? JSON.parse(response.choices[0].message.content) : response.choices[0].message.content 
      });
    }

    if (activeProvider === 'gemini') {
      const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
      const model = genAI.getGenerativeModel({ model: settings.providers.gemini.model });
      
      const fullPrompt = systemPrompt ? `${systemPrompt}\n\nUser: ${prompt}` : prompt;
      const result = await model.generateContent({
        contents: [{ role: 'user', parts: [{ text: fullPrompt }] }],
        generationConfig: { maxOutputTokens: 8000, temperature: 0.8 },
      });
      const response = await result.response;
      const text = response.text();

      return NextResponse.json({ 
        success: true, 
        provider: 'gemini',
        data: format === 'json' ? JSON.parse(text) : text 
      });
    }

    return NextResponse.json({ success: false, message: 'Provider not supported yet' }, { status: 400 });

  } catch (error) {
    console.error('[AI HUB ERROR]', error);
    return NextResponse.json({ success: false, error: error.message }, { status: 500 });
  }
}

export async function GET() {
  const settings = getSettings();
  return NextResponse.json(settings);
}
