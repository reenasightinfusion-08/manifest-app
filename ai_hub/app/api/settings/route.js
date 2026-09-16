import { NextResponse } from 'next/server';
import fs from 'fs';
import path from 'path';

const CONFIG_PATH = path.join(process.cwd(), 'config', 'hub_settings.json');

function getSettings() {
  const file = fs.readFileSync(CONFIG_PATH, 'utf8');
  return JSON.parse(file);
}

function saveSettings(settings) {
  fs.writeFileSync(CONFIG_PATH, JSON.stringify(settings, null, 2));
}

export async function GET() {
  try {
    const settings = getSettings();
    return NextResponse.json(settings);
  } catch (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req) {
  try {
    const { active_provider } = await req.json();
    const settings = getSettings();
    
    if (settings.providers[active_provider]) {
      settings.active_provider = active_provider;
      saveSettings(settings);
      return NextResponse.json(settings);
    }
    
    return NextResponse.json({ error: 'Invalid provider' }, { status: 400 });
  } catch (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
