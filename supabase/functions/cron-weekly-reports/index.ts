import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import {
  buildReportHtml,
  buildWeeklyReport,
  getWeekBounds,
  sendReportEmail,
} from "../_shared/report_builder.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-cron-secret",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const cronSecret = Deno.env.get("CRON_SECRET");
    const requestSecret = req.headers.get("x-cron-secret");

    if (cronSecret && requestSecret !== cronSecret) {
      return jsonResponse({ error: "Cron secret inválido" }, 401);
    }

    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!serviceKey) {
      return jsonResponse({ error: "SERVICE_ROLE_KEY no disponible" }, 503);
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      serviceKey,
    );

    const { data: settings, error: settingsError } = await supabase
      .from("report_email_settings")
      .select("*")
      .eq("auto_send_weekly", true);

    if (settingsError) {
      return jsonResponse({ error: settingsError.message }, 500);
    }

    const { start, end } = getWeekBounds();
    const now = new Date();
    const results: Array<{ patient_id: string; status: string }> = [];

    for (const setting of settings ?? []) {
      const lastSent = setting.last_sent_at
        ? new Date(setting.last_sent_at)
        : null;

      if (lastSent && (now.getTime() - lastSent.getTime()) < 6 * 24 * 60 * 60 * 1000) {
        results.push({ patient_id: setting.patient_id, status: "skipped_recent" });
        continue;
      }

      const { data: profile } = await supabase
        .from("profiles")
        .select("full_name")
        .eq("id", setting.patient_id)
        .single();

      const { data: sessions, error: sessionsError } = await supabase
        .from("cognitive_sessions")
        .select("activity_type, score, completed_at")
        .eq("patient_id", setting.patient_id)
        .gte("completed_at", start.toISOString())
        .lt("completed_at", end.toISOString());

      if (sessionsError) {
        results.push({ patient_id: setting.patient_id, status: "error_sessions" });
        continue;
      }

      if (!sessions || sessions.length === 0) {
        results.push({ patient_id: setting.patient_id, status: "skipped_no_data" });
        continue;
      }

      const report = buildWeeklyReport(sessions);
      const patientName = profile?.full_name ?? "Usuario";
      const periodLabel = `${report.weekStart.toLocaleDateString("es-ES")} – ${report.weekEnd.toLocaleDateString("es-ES")}`;
      const html = buildReportHtml(patientName, report);

      try {
        await sendReportEmail({
          to: setting.recipient_email,
          patientName,
          html,
          periodLabel,
        });

        await supabase
          .from("report_email_settings")
          .update({ last_sent_at: now.toISOString(), updated_at: now.toISOString() })
          .eq("patient_id", setting.patient_id);

        results.push({ patient_id: setting.patient_id, status: "sent" });
      } catch (sendError) {
        results.push({
          patient_id: setting.patient_id,
          status: `error_send: ${sendError}`,
        });
      }
    }

    return jsonResponse({
      success: true,
      processed: results.length,
      results,
    });
  } catch (error) {
    return jsonResponse({ error: String(error) }, 500);
  }
});

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    headers: { ...corsHeaders, "Content-Type": "application/json" },
    status,
  });
}
