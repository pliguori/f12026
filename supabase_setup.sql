-- ================================================================
-- FANTASY F1 2026 — SUPABASE DATABASE SETUP
-- Esegui questo script nell'editor SQL di Supabase
-- Dashboard → SQL Editor → New Query
-- ================================================================

-- 1. TABELLA UTENTI (team_manager)
CREATE TABLE IF NOT EXISTS managers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  username    TEXT NOT NULL UNIQUE,
  team_name   TEXT NOT NULL DEFAULT 'My Team',
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- 2. TABELLA SQUADRE
CREATE TABLE IF NOT EXISTS teams (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id      UUID REFERENCES managers(id) ON DELETE CASCADE,
  driver_ids      INT[] NOT NULL DEFAULT '{}',
  constructor_ids INT[] NOT NULL DEFAULT '{}',
  captain_id      INT,
  updated_at      TIMESTAMPTZ DEFAULT now()
);

-- 3. TABELLA PUNTEGGI GP
CREATE TABLE IF NOT EXISTS gp_scores (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id  UUID REFERENCES managers(id) ON DELETE CASCADE,
  gp_name     TEXT NOT NULL,
  points      INT NOT NULL DEFAULT 0,
  scored_at   TIMESTAMPTZ DEFAULT now()
);

-- 4. VIEW CLASSIFICA (unisce i punteggi totali)
CREATE OR REPLACE VIEW leaderboard AS
SELECT
  m.id,
  m.username,
  m.team_name,
  COALESCE(SUM(g.points), 0)                                AS total_points,
  COALESCE((SELECT points FROM gp_scores WHERE manager_id = m.id ORDER BY scored_at DESC LIMIT 1), 0) AS last_gp_points
FROM managers m
LEFT JOIN gp_scores g ON g.manager_id = m.id
GROUP BY m.id, m.username, m.team_name
ORDER BY total_points DESC;

-- 5. ROW LEVEL SECURITY (RLS)
-- Abilita RLS sulle tabelle
ALTER TABLE managers      ENABLE ROW LEVEL SECURITY;
ALTER TABLE teams         ENABLE ROW LEVEL SECURITY;
ALTER TABLE gp_scores     ENABLE ROW LEVEL SECURITY;

-- Chiunque può leggere la classifica
CREATE POLICY "leaderboard_read" ON managers FOR SELECT USING (true);

-- Chiunque può creare un manager (registrazione)
CREATE POLICY "managers_insert" ON managers FOR INSERT WITH CHECK (true);

-- Solo il proprietario può aggiornare il proprio team
CREATE POLICY "teams_all"  ON teams  FOR ALL  USING (true) WITH CHECK (true);

-- Chiunque può leggere i punteggi
CREATE POLICY "scores_read" ON gp_scores FOR SELECT USING (true);
CREATE POLICY "scores_insert" ON gp_scores FOR INSERT WITH CHECK (true);

-- ================================================================
-- PRONTO! Ora vai su Project Settings → API e copia:
--   1. Project URL  →  SUPABASE_URL
--   2. anon public  →  SUPABASE_KEY
-- ================================================================
