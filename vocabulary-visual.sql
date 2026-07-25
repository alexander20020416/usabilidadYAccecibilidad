-- ============================================
-- ENGLISH UP - Vocabulario Visual Accesible
-- Ejecuta este SQL DESPUÉS de database.sql
-- en el SQL Editor de Supabase
-- ============================================

-- ============================================
-- 1. NUEVAS COLUMNAS EN exercises
-- ============================================

ALTER TABLE exercises
  ADD COLUMN IF NOT EXISTS image_url     TEXT,
  ADD COLUMN IF NOT EXISTS image_alt     TEXT,
  ADD COLUMN IF NOT EXISTS video_url     TEXT,
  ADD COLUMN IF NOT EXISTS video_caption TEXT,
  ADD COLUMN IF NOT EXISTS exercise_type TEXT DEFAULT 'text';

-- Marcar todos los ejercicios existentes como tipo texto
UPDATE exercises
SET exercise_type = 'text'
WHERE exercise_type IS NULL;

-- ============================================
-- 2. CONSTRAINT: solo valores válidos
-- ============================================

ALTER TABLE exercises
  DROP CONSTRAINT IF EXISTS exercises_type_check;

ALTER TABLE exercises
  ADD CONSTRAINT exercises_type_check
  CHECK (exercise_type IN ('text', 'image_choice', 'image_describe'));

-- ============================================
-- 3. ÍNDICE para filtrar por tipo
-- ============================================

CREATE INDEX IF NOT EXISTS idx_exercises_type
  ON exercises (exercise_type);

CREATE INDEX IF NOT EXISTS idx_exercises_module_type
  ON exercises (module, exercise_type);

-- ============================================
-- 4. EJERCICIOS DE VOCABULARIO VISUAL
--    Tipo: image_choice  (imagen + opciones múltiples)
--    Tipo: image_describe (imagen + descripción libre)
--
--    Imágenes: Unsplash (libres de derechos, sin clave de API)
-- ============================================

INSERT INTO exercises (
  module, title, question,
  options, correct_answer, explanation,
  difficulty, order_index,
  exercise_type, image_url, image_alt
) VALUES

-- ── IMAGE CHOICE ─────────────────────────────────────────

-- 1. Fruit: Apple
('vocabulary', 'Visual Vocab – Fruits',
 'Look at the image. What object do you see?',
 '["An apple", "A banana", "An orange", "A mango"]',
 'An apple',
 'This is an apple. Apples are round fruits that are typically red, green, or yellow.',
 'easy', 20,
 'image_choice',
 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=600&q=80&auto=format&fit=crop',
 'A shiny red apple on a white background'),

-- 2. Animal: Cat
('vocabulary', 'Visual Vocab – Animals',
 'Look at the image. What animal is this?',
 '["A dog", "A cat", "A rabbit", "A mouse"]',
 'A cat',
 'This is a cat. Cats are common household pets known for being independent and agile.',
 'easy', 21,
 'image_choice',
 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600&q=80&auto=format&fit=crop',
 'A fluffy orange cat sitting and looking at the camera'),

-- 3. Place: Library
('vocabulary', 'Visual Vocab – Places',
 'Look at the image. What place is this?',
 '["A hospital", "A library", "A restaurant", "A school"]',
 'A library',
 'This is a library. A library is a place where books and other resources are kept for people to read or borrow.',
 'medium', 22,
 'image_choice',
 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=600&q=80&auto=format&fit=crop',
 'Rows of bookshelves filled with books inside a large library'),

-- 4. Weather: Sunny
('vocabulary', 'Visual Vocab – Weather',
 'Look at the image. What is the weather like?',
 '["It is raining", "It is cloudy", "It is sunny", "It is snowing"]',
 'It is sunny',
 'The image shows a bright, clear sky with sunshine. We say the weather is sunny or it is a sunny day.',
 'easy', 23,
 'image_choice',
 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600&q=80&auto=format&fit=crop',
 'A bright blue sky with the sun shining over a mountain landscape'),

-- 5. Transport: Bicycle
('vocabulary', 'Visual Vocab – Transport',
 'Look at the image. What is this vehicle called?',
 '["A motorcycle", "A bicycle", "A scooter", "A tricycle"]',
 'A bicycle',
 'This is a bicycle (also called a bike). It is a human-powered vehicle with two wheels.',
 'easy', 24,
 'image_choice',
 'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=600&q=80&auto=format&fit=crop',
 'A red bicycle parked against a brick wall'),

-- 6. Food: Pizza
('vocabulary', 'Visual Vocab – Food',
 'Look at the image. What food is this?',
 '["Pasta", "A burger", "Pizza", "A sandwich"]',
 'Pizza',
 'This is a pizza. Pizza is an Italian dish with a flat dough base topped with tomato sauce, cheese, and various toppings.',
 'easy', 25,
 'image_choice',
 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80&auto=format&fit=crop',
 'A freshly baked pizza with melted cheese and vegetables on top'),

-- 7. Profession: Doctor
('vocabulary', 'Visual Vocab – Professions',
 'Look at the image. What is this person''s profession?',
 '["A teacher", "A chef", "A doctor", "An engineer"]',
 'A doctor',
 'This is a doctor. Doctors are medical professionals who diagnose and treat illnesses and injuries.',
 'medium', 26,
 'image_choice',
 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=600&q=80&auto=format&fit=crop',
 'A doctor in a white coat holding a stethoscope'),

-- 8. Emotions: Happy
('vocabulary', 'Visual Vocab – Emotions',
 'Look at the image. Which emotion does this person show?',
 '["Sad", "Angry", "Surprised", "Happy"]',
 'Happy',
 'The person in the image is smiling, which shows they are happy. Happy means feeling pleasure and joy.',
 'easy', 27,
 'image_choice',
 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=600&q=80&auto=format&fit=crop',
 'A smiling person with a bright and joyful expression'),

-- 9. Nature: Mountain
('vocabulary', 'Visual Vocab – Nature',
 'Look at the image. What natural feature can you see?',
 '["A river", "A desert", "A forest", "A mountain"]',
 'A mountain',
 'This is a mountain. A mountain is a large natural elevation of the earth''s surface.',
 'easy', 28,
 'image_choice',
 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=600&q=80&auto=format&fit=crop',
 'A snow-capped mountain peak against a blue sky'),

-- 10. Actions: Reading
('vocabulary', 'Visual Vocab – Actions',
 'Look at the image. What action is the person performing?',
 '["Reading a book", "Writing an email", "Painting a picture", "Playing chess"]',
 'Reading a book',
 'The person is reading a book. "Read" is the verb; "reading" is the present participle used for ongoing actions.',
 'medium', 29,
 'image_choice',
 'https://images.unsplash.com/photo-1506880018603-83d5b814b5a6?w=600&q=80&auto=format&fit=crop',
 'A person sitting comfortably and reading a book'),

-- 11. Prepositions: cat on table
('vocabulary', 'Visual Vocab – Prepositions',
 'Look at the image. Where is the cat?',
 '["The cat is under the table", "The cat is on the table", "The cat is behind the table", "The cat is next to the table"]',
 'The cat is on the table',
 '"On" is used for surfaces. The cat is sitting on top of the table: "The cat is on the table."',
 'medium', 30,
 'image_choice',
 'https://images.unsplash.com/photo-1583795128727-6ec3642408f8?w=600&q=80&auto=format&fit=crop',
 'A white cat sitting on top of a wooden table'),

-- 12. Clothing: suit
('vocabulary', 'Visual Vocab – Clothing',
 'Look at the image. What is the person wearing?',
 '["A suit and tie", "Casual jeans and a t-shirt", "A dress", "Sports clothes"]',
 'A suit and tie',
 'The person is wearing a suit (jacket and trousers) with a tie. This is formal business attire.',
 'easy', 31,
 'image_choice',
 'https://images.unsplash.com/photo-1507679799987-c73779587ccf?w=600&q=80&auto=format&fit=crop',
 'A man in a formal blue suit and tie standing in an office setting'),

-- 13. Rooms: living room
('vocabulary', 'Visual Vocab – Home',
 'Look at the image. What room of the house is this?',
 '["The bedroom", "The bathroom", "The living room", "The dining room"]',
 'The living room',
 'This is a living room (also called a lounge or sitting room). It usually has a sofa, chairs, and a TV.',
 'easy', 32,
 'image_choice',
 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=600&q=80&auto=format&fit=crop',
 'A cozy living room with a sofa, coffee table, plants, and soft lighting'),

-- ── IMAGE DESCRIBE ────────────────────────────────────────

-- 14. Describe: Park
('vocabulary', 'Describe the Scene – Park',
 'Look at the image carefully. Write a sentence describing what you see. Try to use words like: people, park, trees, walking, green.',
 '[]',
 'park people trees green walking',
 'Great! A model sentence: "People are walking in a green park surrounded by trees." Key words: park, people, trees, walking, green.',
 'medium', 33,
 'image_describe',
 'https://images.unsplash.com/photo-1519331379826-f10be5486c6f?w=600&q=80&auto=format&fit=crop',
 'Families and people walking through a green park with tall trees on a sunny day'),

-- 15. Describe: Kitchen
('vocabulary', 'Describe the Scene – Kitchen',
 'Look at the image. Describe what you see. Try to use words like: kitchen, cooking, stove, food.',
 '[]',
 'kitchen cooking food stove',
 'Well done! A model sentence: "A person is cooking food on the stove in a modern kitchen." Key words: kitchen, cooking, stove, food.',
 'medium', 34,
 'image_describe',
 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=600&q=80&auto=format&fit=crop',
 'A person cooking food on a stove in a bright modern kitchen'),

-- 16. Describe: Beach
('vocabulary', 'Describe the Scene – Beach',
 'Look at the image. Write a sentence about what you see. Try to use words like: sea, sand, waves, people, summer, blue.',
 '[]',
 'sea sand beach waves blue summer',
 'Excellent! A model sentence: "People are relaxing on the sand near the blue sea with waves." Key words: beach, sea, sand, waves.',
 'hard', 35,
 'image_describe',
 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&q=80&auto=format&fit=crop',
 'A beautiful beach with clear blue water, white sand, and gentle waves on a sunny day'),

-- 17. Describe: City street
('vocabulary', 'Describe the Scene – City',
 'Look at the image. Describe the city scene. Try to use words like: buildings, street, people, busy, tall, walking.',
 '[]',
 'city buildings street people busy walking tall',
 'Great work! A model description: "People are walking on a busy city street surrounded by tall buildings." Key words: city, buildings, street.',
 'hard', 36,
 'image_describe',
 'https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=600&q=80&auto=format&fit=crop',
 'A busy city street with tall buildings, cars, and many people walking on the sidewalk'),

-- 18. Describe: Classroom (advanced)
('vocabulary', 'Describe the Scene – Classroom',
 'Look at the image. Write 1–2 sentences describing what you see. Try to use words like: students, teacher, classroom, desks, learning, board.',
 '[]',
 'students classroom desks teacher learning board',
 'Excellent! A model answer: "Students are sitting at desks in a classroom while the teacher writes on the board." Key words: students, classroom, desks.',
 'hard', 37,
 'image_describe',
 'https://images.unsplash.com/photo-1580582932707-520aed937b7b?w=600&q=80&auto=format&fit=crop',
 'A classroom with students sitting at desks and a teacher standing near a whiteboard');

-- ============================================
-- 5. VERIFICACIÓN (descomenta para revisar)
-- ============================================

-- SELECT id, module, title, exercise_type, image_url IS NOT NULL AS has_image
-- FROM exercises
-- WHERE exercise_type IN ('image_choice', 'image_describe')
-- ORDER BY order_index;

-- SELECT exercise_type, COUNT(*) AS total
-- FROM exercises
-- GROUP BY exercise_type;
