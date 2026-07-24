-- ============================================
-- ENGLISH UP - Supabase Database Schema
-- Ejecuta TODO este SQL en el SQL Editor de Supabase
-- ============================================

-- 1. TABLAS
-- ============================================

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  level TEXT DEFAULT 'A1',
  streak INTEGER DEFAULT 0,
  total_exercises INTEGER DEFAULT 0,
  accuracy INTEGER DEFAULT 0,
  last_active DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module TEXT NOT NULL,
  title TEXT NOT NULL,
  question TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT,
  difficulty TEXT DEFAULT 'easy',
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  exercise_id UUID REFERENCES exercises(id) ON DELETE CASCADE,
  is_correct BOOLEAN NOT NULL,
  user_answer TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS daily_streak (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  exercises_done INTEGER DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, date)
);

CREATE TABLE IF NOT EXISTS scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  percentage INTEGER NOT NULL,
  module TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. AUTO-PROFILE: se crea automaticamente al registrarse
-- ============================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, level, streak, total_exercises, accuracy)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    'A1',
    0,
    0,
    0
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 3. AUTO-UPDATE updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON profiles;
CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- 4. ROW LEVEL SECURITY (RLS)
-- ============================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_streak ENABLE ROW LEVEL SECURITY;
ALTER TABLE scores ENABLE ROW LEVEL SECURITY;

-- Permisos base para la API web.
-- Las politicas RLS de abajo siguen limitando cada fila al usuario propietario.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON TABLE public.exercises TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated;
GRANT SELECT, INSERT ON TABLE public.user_progress TO authenticated;
GRANT SELECT, INSERT ON TABLE public.daily_streak TO authenticated;
GRANT SELECT, INSERT ON TABLE public.scores TO authenticated;

-- Profiles
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON profiles;

CREATE POLICY "Users can view own profile" ON profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Exercises (publicos)
DROP POLICY IF EXISTS "Anyone can read exercises" ON exercises;
CREATE POLICY "Anyone can read exercises" ON exercises
  FOR SELECT USING (true);

-- User Progress
DROP POLICY IF EXISTS "Users can view own progress" ON user_progress;
DROP POLICY IF EXISTS "Users can insert own progress" ON user_progress;

CREATE POLICY "Users can view own progress" ON user_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress" ON user_progress
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Daily Streak
DROP POLICY IF EXISTS "Users can view own streak" ON daily_streak;
DROP POLICY IF EXISTS "Users can insert own streak" ON daily_streak;

CREATE POLICY "Users can view own streak" ON daily_streak
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own streak" ON daily_streak
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Scores
DROP POLICY IF EXISTS "Users can view own scores" ON scores;
DROP POLICY IF EXISTS "Users can insert own scores" ON scores;

CREATE POLICY "Users can view own scores" ON scores
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own scores" ON scores
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5. FUNCION: progreso por modulo
-- ============================================

CREATE OR REPLACE FUNCTION get_module_progress(p_user_id UUID, p_module TEXT)
RETURNS TABLE(total BIGINT, completed BIGINT, percentage BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT
    (SELECT COUNT(*)::BIGINT FROM exercises WHERE module = p_module) as total,
    (SELECT COUNT(DISTINCT e.id)::BIGINT
     FROM exercises e
     JOIN user_progress up ON up.exercise_id = e.id
     WHERE e.module = p_module AND up.user_id = p_user_id AND up.is_correct = true) as completed,
    CASE
      WHEN (SELECT COUNT(*) FROM exercises WHERE module = p_module) = 0 THEN 0
      ELSE ROUND((SELECT COUNT(DISTINCT e.id)::NUMERIC
       FROM exercises e
       JOIN user_progress up ON up.exercise_id = e.id
       WHERE e.module = p_module AND up.user_id = p_user_id AND up.is_correct = true)
       / (SELECT COUNT(*)::NUMERIC FROM exercises WHERE module = p_module) * 100)::BIGINT
    END as percentage;
END;
$$ LANGUAGE plpgsql;

-- 6. DATOS DE EJEMPLO: Ejercicios iniciales
-- ============================================

-- Limpia datos previos para evitar duplicados
DELETE FROM exercises;

INSERT INTO exercises (module, title, question, options, correct_answer, explanation, difficulty, order_index) VALUES

-- GRAMMAR: Past Perfect
('grammar', 'Past Perfect - Exercise 1',
 'By the time she arrived, they ________ for two hours.',
 '["had been waiting", "have been waiting", "were waiting", "are waiting"]',
 'had been waiting',
 'Past perfect continuous for an ongoing action before another past event.',
 'easy', 1),

('grammar', 'Past Perfect - Exercise 2',
 'I ________ English for five years before I moved to London.',
 '["studied", "had studied", "have studied", "was studying"]',
 'had studied',
 'Past perfect shows one action happened before another in the past.',
 'easy', 2),

('grammar', 'Past Perfect - Exercise 3',
 'She ________ all the emails before the meeting started.',
 '["had read", "has read", "was reading", "reads"]',
 'had read',
 'Past perfect for an action completed before another past action.',
 'medium', 3),

-- GRAMMAR: Conditionals
('grammar', 'Conditionals - Exercise 1',
 'If I ________ more time, I would travel the world.',
 '["have", "had", "would have", "will have"]',
 'had',
 'Second conditional: If + past simple, would + base form.',
 'easy', 4),

('grammar', 'Conditionals - Exercise 2',
 'If it ________ tomorrow, we will cancel the picnic.',
 '["rains", "rained", "would rain", "will rain"]',
 'rains',
 'First conditional: If + present simple, will + base form.',
 'easy', 5),

('grammar', 'Conditionals - Exercise 3',
 'If she ________ the exam, she would have been accepted.',
 '["passes", "passed", "had passed", "would pass"]',
 'had passed',
 'Third conditional: If + past perfect, would have + past participle.',
 'medium', 6),

-- GRAMMAR: Passive Voice
('grammar', 'Passive Voice - Exercise 1',
 'The letter ________ by the secretary yesterday.',
 '["wrote", "was written", "is written", "written"]',
 'was written',
 'Passive voice in past simple: was/were + past participle.',
 'medium', 7),

('grammar', 'Passive Voice - Exercise 2',
 'English ________ all over the world.',
 '["speak", "is spoken", "spoke", "speaking"]',
 'is spoken',
 'Present simple passive: is/are + past participle.',
 'easy', 8),

-- GRAMMAR: Modal Verbs
('grammar', 'Modal Verbs - Exercise 1',
 'You ________ finish your homework before playing.',
 '["must", "can", "might", "could"]',
 'must',
 'Must expresses obligation or necessity.',
 'easy', 9),

('grammar', 'Modal Verbs - Exercise 2',
 '________ I borrow your pen, please?',
 '["Must", "May", "Need", "Shall"]',
 'May',
 'May is used to ask for permission politely.',
 'easy', 10),

-- VOCABULARY: Synonyms
('vocabulary', 'Synonyms - Exercise 1',
 'Which word is a synonym of "happy"?',
 '["sad", "joyful", "angry", "tired"]',
 'joyful',
 'Happy and joyful both express positive emotion.',
 'easy', 1),

('vocabulary', 'Synonyms - Exercise 2',
 'Which word is a synonym of "important"?',
 '["trivial", "significant", "small", "quick"]',
 'significant',
 'Important and significant share the meaning of having great value.',
 'easy', 2),

('vocabulary', 'Synonyms - Exercise 3',
 'Which word is a synonym of "fast"?',
 '["slow", "quick", "heavy", "loud"]',
 'quick',
 'Fast and quick both mean moving at high speed.',
 'easy', 3),

('vocabulary', 'Antonyms - Exercise 1',
 'Which word is the opposite of "broad"?',
 '["wide", "narrow", "large", "deep"]',
 'narrow',
 'Broad means wide; narrow is its opposite.',
 'easy', 4),

('vocabulary', 'Antonyms - Exercise 2',
 'Which word is the opposite of "ancient"?',
 '["old", "modern", "historic", "aged"]',
 'modern',
 'Ancient means very old; modern means recent or new.',
 'easy', 5),

('vocabulary', 'Phrasal Verbs - Exercise 1',
 'Please ________ the light, it is too dark.',
 '["turn on", "turn off", "turn up", "turn down"]',
 'turn on',
 'Turn on means to activate or start (a device or light).',
 'easy', 6),

('vocabulary', 'Phrasal Verbs - Exercise 2',
 'I need to ________ this word in the dictionary.',
 '["look for", "look up", "look after", "look into"]',
 'look up',
 'Look up means to search for information in a reference source.',
 'medium', 7),

-- WRITING: Past Simple
('writing', 'Past Simple - Exercise 1',
 'Complete: Yesterday, I ________ to the store and bought some groceries.',
 '["go", "went", "have gone", "going"]',
 'went',
 'Past simple for completed actions in the past: go → went.',
 'easy', 1),

('writing', 'Past Simple - Exercise 2',
 'She ________ a beautiful song at the concert last night.',
 '["sing", "sang", "sung", "sings"]',
 'sang',
 'Past simple irregular: sing → sang.',
 'easy', 2),

('writing', 'Past Simple - Exercise 3',
 'They ________ to Paris in 2019.',
 '["travel", "travelled", "travels", "travelling"]',
 'travelled',
 'Past simple regular: travel → travelled.',
 'easy', 3),

-- WRITING: Present Perfect
('writing', 'Present Perfect - Exercise 1',
 'I ________ never ________ to Japan.',
 '["have...been", "has...been", "did...go", "was...going"]',
 'have...been',
 'Present perfect: have/has + past participle for experiences.',
 'medium', 4),

('writing', 'Present Perfect - Exercise 2',
 'She ________ already finished her project.',
 '["has", "have", "did", "was"]',
 'has',
 'Present perfect with third person singular: has + past participle.',
 'medium', 5),

('writing', 'Present Perfect - Exercise 3',
 'They ________ living here for ten years.',
 '["have been", "has been", "are", "were"]',
 'have been',
 'Present perfect continuous: have/has been + -ing form.',
 'medium', 6),

-- WRITING: Reported Speech
('writing', 'Reported Speech - Exercise 1',
 'She said she ________ coming to the party.',
 '["is", "was", "will be", "has been"]',
 'was',
 'In reported speech, present changes to past: is → was.',
 'hard', 7),

('writing', 'Reported Speech - Exercise 2',
 'He told me that he ________ the movie already.',
 '["sees", "saw", "had seen", "has seen"]',
 'had seen',
 'In reported speech, past simple → past perfect: saw → had seen.',
 'hard', 8);

-- =============================================
-- SPEAKING EXERCISES
-- =============================================

INSERT INTO exercises (module, title, question, options, correct_answer, explanation, difficulty, order_index) VALUES

-- A1: Basic Greetings & Simple Sentences
('speaking', 'Greeting', 'Read aloud: Hello, how are you?',
 '[]', 'Hello, how are you?',
 'Focus on the "h" sound in "how" and the rising intonation at the end.',
 'easy', 1),

('speaking', 'Introduction', 'Read aloud: My name is John and I am from Canada.',
 '[]', 'My name is John and I am from Canada.',
 'Practice the "j" in John and the "c" sound in Canada (hard k sound).',
 'easy', 2),

('speaking', 'Daily Routine', 'Read aloud: I wake up at seven o''clock every morning.',
 '[]', 'I wake up at seven o''clock every morning.',
 'Stress "seven" and "morning". The "ck" in clock is a quick k sound.',
 'easy', 3),

('speaking', 'Family', 'Read aloud: I have two brothers and one sister.',
 '[]', 'I have two brothers and one sister.',
 'The "th" in "three" and "brothers" should be voiced (vibrate your throat).',
 'easy', 4),

('speaking', 'Food', 'Read aloud: I would like a coffee with milk, please.',
 '[]', 'I would like a coffee with milk, please.',
 'Contract "I would" to "I''d". Stress "coffee" and "please".',
 'easy', 5),

-- A2: Everyday Conversations
('speaking', 'Weather', 'Read aloud: The weather is really nice today, isn''t it?',
 '[]', 'The weather is really nice today, isn''t it?',
 'Use rising intonation on "isn''t it?" for the tag question.',
 'easy', 6),

('speaking', 'Shopping', 'Read aloud: How much does this shirt cost? It looks expensive.',
 '[]', 'How much does this shirt cost? It looks expensive.',
 'Stress "much" and "expensive". The "sh" in shirt is a soft sound.',
 'easy', 7),

('speaking', 'Directions', 'Read aloud: Turn left at the traffic light, then go straight for two blocks.',
 '[]', 'Turn left at the traffic light, then go straight for two blocks.',
 'Stress the key directions: left, light, straight, blocks.',
 'easy', 8),

('speaking', 'Restaurant', 'Read aloud: Can I see the menu, please? I''m ready to order.',
 '[]', 'Can I see the menu, please? I''m ready to order.',
 'Rising intonation on "please?" and stress "ready" and "order".',
 'easy', 9),

('speaking', 'Weekend', 'Read aloud: Last weekend I went to the movies with my friends.',
 '[]', 'Last weekend I went to the movies with my friends.',
 'Past tense: "went" not "goed". Stress "weekend" and "movies".',
 'easy', 10),

-- B1: Intermediate Topics
('speaking', 'Technology', 'Read aloud: Technology has changed the way we communicate with each other.',
 '[]', 'Technology has changed the way we communicate with each other.',
 'Stress "technology" and "communicate". The "ch" in communicate is a k sound.',
 'medium', 11),

('speaking', 'Environment', 'Read aloud: We should recycle more and use less plastic to protect the environment.',
 '[]', 'We should recycle more and use less plastic to protect the environment.',
 'Stress "recycle", "less", "plastic", "protect", "environment".',
 'medium', 12),

('speaking', 'Travel', 'Read aloud: I''ve always wanted to visit Japan because of its beautiful culture.',
 '[]', 'I''ve always wanted to visit Japan because of its beautiful culture.',
 'Use present perfect: "I''ve" not "I have". Stress "Japan" and "beautiful".',
 'medium', 13),

('speaking', 'Health', 'Read aloud: Drinking enough water every day is important for your health.',
 '[]', 'Drinking enough water every day is important for your health.',
 'The "dr" in drinking is a blend sound. Stress "enough", "important", "health".',
 'medium', 14),

('speaking', 'Education', 'Read aloud: Learning a new language opens doors to different cultures.',
 '[]', 'Learning a new language opens doors to different cultures.',
 'Stress "learning", "language", "doors", "cultures". The "ng" in learning is a nasal sound.',
 'medium', 15),

-- B1+: Complex Sentences
('speaking', 'Opinions', 'Read aloud: In my opinion, social media has both positive and negative effects on society.',
 '[]', 'In my opinion, social media has both positive and negative effects on society.',
 'Pause after "opinion". Stress "positive", "negative", "effects".',
 'medium', 16),

('speaking', 'Comparison', 'Read aloud: Online shopping is more convenient than going to physical stores.',
 '[]', 'Online shopping is more convenient than going to physical stores.',
 ' comparative form: "more convenient than". Stress "online", "convenient", "physical".',
 'medium', 17),

('speaking', 'Future Plans', 'Read aloud: I''m planning to travel around Europe next summer with my family.',
 '[]', 'I''m planning to travel around Europe next summer with my family.',
 'Use "I''m planning to" for future plans. Stress "Europe", "summer", "family".',
 'medium', 18),

('speaking', 'Work', 'Read aloud: Working from home gives employees more flexibility and better work-life balance.',
 '[]', 'Working from home gives employees more flexibility and better work-life balance.',
 'Stress "flexibility" and "balance". The "x" in flexibility is a ks sound.',
 'medium', 19),

('speaking', 'Culture', 'Read aloud: Different cultures have unique traditions that make the world more interesting.',
 '[]', 'Different cultures have unique traditions that make the world more interesting.',
 'Stress "different", "unique", "traditions", "interesting".',
 'medium', 20),

-- B2: Advanced Topics
('speaking', 'Debate', 'Read aloud: While some people believe technology isolates us, others argue it brings people together.',
 '[]', 'While some people believe technology isolates us, others argue it brings people together.',
 'Pause after "us". Contrast stress: "isolates" vs "brings together".',
 'hard', 21),

('speaking', 'Academic', 'Read aloud: Research shows that students who read regularly perform better in all subjects.',
 '[]', 'Research shows that students who read regularly perform better in all subjects.',
 'Stress "research", "regularly", "perform", "all". The "sh" in research is soft.',
 'hard', 22),

('speaking', 'Persuasion', 'Read aloud: Governments should invest more in public transportation to reduce carbon emissions.',
 '[]', 'Governments should invest more in public transportation to reduce carbon emissions.',
 'Stress "governments", "invest", "public", "reduce", "emissions".',
 'hard', 23),

('speaking', 'Narrative', 'Read aloud: The moment I stepped off the plane, I knew this trip would change my life forever.',
 '[]', 'The moment I stepped off the plane, I knew this trip would change my life forever.',
 'Pause after "plane". Stress "moment", "stepped", "knew", "change", "forever".',
 'hard', 24),

('speaking', 'Abstract', 'Read aloud: Success is not just about achieving goals, but also about the journey and lessons learned along the way.',
 '[]', 'Success is not just about achieving goals, but also about the journey and lessons learned along the way.',
 'Stress "success", "achieving", "journey", "lessons". Use natural pauses at commas.',
 'hard', 25);
