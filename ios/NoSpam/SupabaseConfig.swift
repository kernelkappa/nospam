import Foundation

/// The publishable (anon) key is safe to embed in client code by design —
/// access control is enforced server-side by Postgres RLS, not by key secrecy.
enum SupabaseConfig {
    static let url = URL(string: "https://xmlluceotrfmltfjuofi.supabase.co")!
    static let publishableKey = "sb_publishable_-LLyPJH9jTsOLxZ0R7PAZg_NubRINac"
}
