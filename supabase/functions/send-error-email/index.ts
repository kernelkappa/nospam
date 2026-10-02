// Edge Function invocata da un Database Webhook su INSERT nella tabella
// error_reports (vedi data-ingestion/supabase_schema.sql): inoltra il log
// di errore via email usando Gmail SMTP (l'account GMAIL_USER è usato solo
// per l'invio, non riceve nulla: il destinatario è sempre TO_ADDRESS).
//
// Setup una tantum (non in questo repo):
// 1. Attivare la verifica in 2 passaggi sull'account Gmail mittente.
// 2. Generare una App Password su myaccount.google.com/apppasswords.
// 3. supabase secrets set GMAIL_USER=<email mittente> GMAIL_APP_PASSWORD=<app password>
// 4. supabase functions deploy send-error-email --no-verify-jwt
// 5. Dashboard Supabase > Database > Webhooks: tabella error_reports,
//    evento INSERT, tipo "Supabase Edge Functions" verso questa function.
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

const GMAIL_USER = Deno.env.get("GMAIL_USER")!;
const GMAIL_APP_PASSWORD = Deno.env.get("GMAIL_APP_PASSWORD")!;
const TO_ADDRESS = "nospamapp1@gmail.com";

Deno.serve(async (req) => {
  const payload = await req.json();
  const record = payload.record ?? payload;
  const { platform, context, message, app_version, os_version, reported_at } = record;

  const text = [
    `Piattaforma: ${platform}`,
    `Contesto: ${context}`,
    `Versione app: ${app_version ?? "n/d"}`,
    `Versione OS: ${os_version ?? "n/d"}`,
    `Quando: ${reported_at}`,
    "",
    "Messaggio errore:",
    message,
  ].join("\n");

  const client = new SMTPClient({
    connection: {
      hostname: "smtp.gmail.com",
      port: 465,
      tls: true,
      auth: {
        username: GMAIL_USER,
        password: GMAIL_APP_PASSWORD,
      },
    },
  });

  try {
    await client.send({
      from: GMAIL_USER,
      to: TO_ADDRESS,
      subject: `[NoSpam ${platform}] ${context}`,
      content: text,
    });
    return new Response("ok", { status: 200 });
  } catch (error) {
    return new Response(String(error), { status: 500 });
  } finally {
    await client.close();
  }
});
