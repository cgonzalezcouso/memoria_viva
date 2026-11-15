export const ACTIVITY_LABELS: Record<string, string> = {
  memoria: "Juego de memoria",
  atencion: "Ejercicio de atención",
  orientacion: "Orientación temporal",
  categorias: "Asociación de categorías",
  secuencias: "Orden de secuencias",
  calculo: "Cálculo sencillo",
  emociones: "Reconocimiento de emociones",
  intruso: "Encuentra el intruso",
  recuerdo: "Memoria inmediata",
  musica: "Música e instrumentos",
  familia: "Recuerdos familiares",
  naturaleza: "Naturaleza y estaciones",
  cocina: "Cocina y alimentación",
};

export function activityLabel(type: string): string {
  return ACTIVITY_LABELS[type] ?? "Actividad cognitiva";
}

export interface CognitiveSessionRow {
  activity_type: string;
  score: number;
  completed_at: string;
}

export interface WeeklyReportData {
  weekStart: Date;
  weekEnd: Date;
  totalSessions: number;
  averageScore: number;
  sessionsByActivity: Record<string, number>;
  averageByActivity: Record<string, number>;
  dailySummaries: Array<{
    date: Date;
    sessionCount: number;
    averageScore: number;
  }>;
}

export function getWeekBounds(reference = new Date()): { start: Date; end: Date } {
  const start = new Date(reference);
  start.setHours(0, 0, 0, 0);
  const day = start.getDay();
  const diff = day === 0 ? 6 : day - 1;
  start.setDate(start.getDate() - diff);

  const end = new Date(start);
  end.setDate(end.getDate() + 7);
  return { start, end };
}

export function buildWeeklyReport(sessions: CognitiveSessionRow[]): WeeklyReportData {
  const { start, end } = getWeekBounds();
  const weekSessions = sessions.filter((s) => {
    const d = new Date(s.completed_at);
    return d >= start && d < end;
  });

  const sessionsByActivity: Record<string, number> = {};
  const scoreSumByActivity: Record<string, number> = {};
  const dailyMap = new Map<string, number[]>();

  for (const session of weekSessions) {
    sessionsByActivity[session.activity_type] =
      (sessionsByActivity[session.activity_type] ?? 0) + 1;
    scoreSumByActivity[session.activity_type] =
      (scoreSumByActivity[session.activity_type] ?? 0) + session.score;

    const dayKey = session.completed_at.slice(0, 10);
    const list = dailyMap.get(dayKey) ?? [];
    list.push(session.score);
    dailyMap.set(dayKey, list);
  }

  const averageByActivity: Record<string, number> = {};
  for (const [type, count] of Object.entries(sessionsByActivity)) {
    averageByActivity[type] = scoreSumByActivity[type] / count;
  }

  const dailySummaries = Array.from({ length: 7 }, (_, i) => {
    const date = new Date(start);
    date.setDate(date.getDate() + i);
    const key = date.toISOString().slice(0, 10);
    const scores = dailyMap.get(key) ?? [];
    return {
      date,
      sessionCount: scores.length,
      averageScore: scores.length
        ? scores.reduce((a, b) => a + b, 0) / scores.length
        : 0,
    };
  });

  const totalScore = weekSessions.reduce((sum, s) => sum + s.score, 0);
  const weekEndDisplay = new Date(start);
  weekEndDisplay.setDate(weekEndDisplay.getDate() + 6);

  return {
    weekStart: start,
    weekEnd: weekEndDisplay,
    totalSessions: weekSessions.length,
    averageScore: weekSessions.length ? totalScore / weekSessions.length : 0,
    sessionsByActivity,
    averageByActivity,
    dailySummaries,
  };
}

export function buildReportHtml(
  patientName: string,
  report: WeeklyReportData,
): string {
  const formatDate = (d: Date) =>
    d.toLocaleDateString("es-ES", { day: "numeric", month: "short", year: "numeric" });

  const periodLabel = `${formatDate(report.weekStart)} – ${formatDate(report.weekEnd)}`;
  const maxSessions = Math.max(
    1,
    ...report.dailySummaries.map((d) => d.sessionCount),
  );

  const dayBars = report.dailySummaries
    .map((day) => {
      const label = day.date.toLocaleDateString("es-ES", { weekday: "short" });
      const height = day.sessionCount === 0
        ? 4
        : Math.round((day.sessionCount / maxSessions) * 100);
      return `
        <td style="text-align:center;vertical-align:bottom;padding:4px;">
          <div style="font-size:11px;margin-bottom:4px;">${day.sessionCount || ""}</div>
          <div style="width:28px;height:${height}px;background:#1B5E7A;margin:0 auto;border-radius:4px 4px 0 0;"></div>
          <div style="font-size:11px;margin-top:4px;text-transform:capitalize;">${label}</div>
        </td>`;
    })
    .join("");

  const maxActivity = Math.max(1, ...Object.values(report.sessionsByActivity));
  const activityBars = Object.entries(report.sessionsByActivity)
    .map(([type, count]) => {
      const width = Math.round((count / maxActivity) * 100);
      const avg = report.averageByActivity[type]?.toFixed(0) ?? "0";
      return `
        <tr>
          <td style="padding:6px 0;font-size:13px;">${activityLabel(type)}</td>
          <td style="padding:6px 0;width:55%;">
            <div style="background:#e0e0e0;height:12px;border-radius:6px;">
              <div style="width:${width}%;background:#2E7D5A;height:12px;border-radius:6px;"></div>
            </div>
          </td>
          <td style="padding:6px 0;text-align:right;font-size:13px;">${count} · ${avg} pts</td>
        </tr>`;
    })
    .join("");

  const dailyRows = report.dailySummaries
    .map((day) => {
      const label = day.date.toLocaleDateString("es-ES", { weekday: "long" });
      return `<tr>
        <td style="padding:8px;border-bottom:1px solid #eee;text-transform:capitalize;">${label}</td>
        <td style="padding:8px;border-bottom:1px solid #eee;text-align:center;">${day.sessionCount}</td>
        <td style="padding:8px;border-bottom:1px solid #eee;text-align:center;">${
        day.sessionCount ? day.averageScore.toFixed(0) : "—"
      }</td>
      </tr>`;
    })
    .join("");

  return `<!DOCTYPE html>
<html><head><meta charset="utf-8"></head>
<body style="font-family:Arial,sans-serif;color:#1a1a1a;max-width:640px;margin:0 auto;padding:24px;">
  <h1 style="color:#1B5E7A;margin:0;">Memoria Viva</h1>
  <p style="color:#555;">Informe semanal automático de estimulación cognitiva</p>
  <p><strong>Persona:</strong> ${patientName}<br><strong>Periodo:</strong> ${periodLabel}</p>

  <table style="width:100%;margin:20px 0;border-collapse:collapse;">
    <tr>
      <td style="background:#f7f4ef;padding:16px;border-radius:8px;width:48%;">
        <div style="font-size:28px;font-weight:bold;">${report.totalSessions}</div>
        <div style="font-size:12px;">Sesiones totales</div>
      </td>
      <td style="width:4%;"></td>
      <td style="background:#f7f4ef;padding:16px;border-radius:8px;width:48%;">
        <div style="font-size:28px;font-weight:bold;">${report.averageScore.toFixed(0)}</div>
        <div style="font-size:12px;">Puntuación media</div>
      </td>
    </tr>
  </table>

  <h2 style="font-size:16px;color:#1B5E7A;">Actividad por día</h2>
  <table style="width:100%;border-collapse:collapse;margin-bottom:8px;"><tr>${dayBars}</tr></table>

  <h2 style="font-size:16px;color:#1B5E7A;">Puntuación media diaria</h2>
  <table style="width:100%;border-collapse:collapse;margin-bottom:20px;">
    <thead><tr style="background:#f0f0f0;">
      <th style="padding:8px;text-align:left;">Día</th>
      <th style="padding:8px;">Sesiones</th>
      <th style="padding:8px;">Media (pts)</th>
    </tr></thead>
    <tbody>${dailyRows}</tbody>
  </table>

  <h2 style="font-size:16px;color:#1B5E7A;">Por tipo de ejercicio</h2>
  <table style="width:100%;border-collapse:collapse;margin-bottom:24px;">${activityBars}</table>

  <p style="font-size:11px;color:#777;border-top:1px solid #eee;padding-top:16px;">
    Informe generado automáticamente. Es orientativo y no sustituye evaluación clínica.<br>
    — Memoria Viva
  </p>
</body></html>`;
}

export async function sendReportEmail(options: {
  to: string;
  patientName: string;
  html: string;
  periodLabel: string;
}): Promise<void> {
  const resendKey = Deno.env.get("RESEND_API_KEY");
  const fromEmail = Deno.env.get("REPORT_FROM_EMAIL") ??
    "Memoria Viva <onboarding@resend.dev>";

  if (!resendKey) {
    throw new Error("RESEND_API_KEY no configurada");
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${resendKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: fromEmail,
      to: [options.to],
      subject: `Informe semanal Memoria Viva — ${options.patientName}`,
      html: options.html,
    }),
  });

  if (!response.ok) {
    throw new Error(`Resend: ${await response.text()}`);
  }
}
