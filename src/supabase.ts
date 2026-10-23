import { createClient } from '@supabase/supabase-js';

// These are public client credentials. Database access is protected by Auth + RLS.
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL || 'https://vzjgnyjstsypfmkhfnhc.supabase.co';
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY || 'sb_publishable_G8R2E9AreQyNMBoWzoIdAw_2ys7vYaP';

export const supabase = createClient(supabaseUrl, supabaseKey);
