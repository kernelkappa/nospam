package com.konrad.nospam

/**
 * The publishable (anon) key is safe to embed in client code by design —
 * access control is enforced server-side by Postgres RLS, not by key secrecy.
 */
object SupabaseConfig {
    const val URL = "https://xmlluceotrfmltfjuofi.supabase.co"
    const val PUBLISHABLE_KEY = "sb_publishable_-LLyPJH9jTsOLxZ0R7PAZg_NubRINac"
}
