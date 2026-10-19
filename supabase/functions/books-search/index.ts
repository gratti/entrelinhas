const corsHeaders = {
  "Access-Control-Allow-Origin": "https://gratti.github.io",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "Método não permitido." }, 405);
  }

  let query: string;
  try {
    const body = await request.json();
    query = typeof body?.query === "string" ? body.query.trim() : "";
  } catch {
    return json({ error: "Busca inválida." }, 400);
  }
  if (query.length < 3 || query.length > 120) {
    return json({ error: "A busca deve ter entre 3 e 120 caracteres." }, 400);
  }

  const apiKey = Deno.env.get("GOOGLE_BOOKS_API_KEY");
  if (!apiKey) {
    return json({ error: "A busca do Google Books ainda não está configurada." }, 503);
  }

  const url = new URL("https://www.googleapis.com/books/v1/volumes");
  url.searchParams.set("q", query);
  url.searchParams.set("langRestrict", "pt");
  url.searchParams.set("maxResults", "6");
  url.searchParams.set("printType", "books");

  try {
    const response = await fetch(url, { headers: { "x-goog-api-key": apiKey }, signal: AbortSignal.timeout(8000) });
    if (!response.ok) {
      console.error("Google Books request failed:", response.status);
      return json({ error: "Não foi possível consultar o Google Books agora." }, 502);
    }

    const payload = await response.json();
    const items = (payload.items || [])
      .map((item: { volumeInfo?: { title?: string; authors?: string[]; publishedDate?: string } }) => {
        const info = item.volumeInfo || {};
        return {
          title: info.title || "",
          authors: Array.isArray(info.authors) ? info.authors : [],
          publishedDate: info.publishedDate || "",
        };
      })
      .filter((item: { title: string }) => item.title);

    return json({ items });
  } catch (error) {
    console.error("Google Books request error:", error);
    return json({ error: "Não foi possível consultar o Google Books agora." }, 502);
  }
});
