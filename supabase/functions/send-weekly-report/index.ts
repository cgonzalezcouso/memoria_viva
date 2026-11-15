import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

interface SendReportPayload {
  recipient_email: string;
  patient_name: string;
  period_label: string;
  pdf_base64: string;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonError("No autorizado", 401);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return jsonError("Sesión no válida", 401);
    }

    const body = (await req.json()) as SendReportPayload;
    const { recipient_email, patient_name, period_label, pdf_base64 } = body;

    if (!recipient_email?.includes("@") || !pdf_base64) {
      return jsonError("Datos incompletos", 400);
    }

    const resendKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("REPORT_FROM_EMAIL") ??
      "Memoria Viva <onboarding@resend.dev>";

    if (!resendKey) {
      return jsonError(
        "RESEND_API_KEY no configurada en el proyecto Supabase",
        503,
      );
    }

    const resendResponse = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromEmail,
        to: [recipient_email],
        subject: `Informe semanal Memoria Viva — ${patient_name}`,
        html: `
          <p>Hola,</p>
          <p>Adjuntamos el informe semanal de estimulación cognitiva de <strong>${patient_name}</strong>.</p>
          <p><strong>Periodo:</strong> ${period_label}</p>
          <p>Este informe es orientativo y no sustituye evaluación clínica.</p>
          <p>— Memoria Viva</p>
        `,
        attachments: [
          {
            filename: "informe_semanal_memoria_viva.pdf",
            content: pdf_base64,
          },
        ],
      }),
    });

    if (!resendResponse.ok) {
      const errorText = await resendResponse.text();
      return jsonError(`Resend: ${errorText}`, 502);
    }

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    return jsonError(String(error), 500);
  }
});

function jsonError(message: string, status: number) {
  return new Response(JSON.stringify({ error: message }), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}
