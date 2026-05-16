import logging
from typing import Optional
from django.conf import settings

logger = logging.getLogger(__name__)


NOTE_TYPES = {
    'summary': 'summarized notes',
    'detailed': 'detailed notes',
    'revision': 'revision notes',
    'bullet': 'bullet-point notes',
}

PROMPTS = {
    'summary': """You are an expert educator and note-taker. Create clear, concise SUMMARY NOTES from the content below.

Structure:
## Key Concepts
- List 5-10 most important concepts

## Core Ideas
Brief paragraphs summarizing main ideas (3-5 paragraphs)

## Key Takeaways
- 5-7 actionable bullet points

Content to summarize:
{content}

Topic (if specified): {topic}
Grade/Level: {level}
""",

    'detailed': """You are an expert educator. Create COMPREHENSIVE DETAILED NOTES from the content below.

Structure:
## Introduction
## Main Topics (with subsections)
## Examples and Applications
## Important Formulas/Definitions (if applicable)
## Summary
## Further Reading Suggestions

Be thorough, clear, and educational.

Content:
{content}

Topic: {topic}
Level: {level}
""",

    'revision': """Create concise REVISION NOTES optimized for quick review before an exam.

Format:
## Quick Reference Sheet
## Must-Know Definitions
## Key Formulas/Rules
## Common Mistakes to Avoid
## Memory Tricks

Make it scannable and memorable.

Content:
{content}

Topic: {topic}
""",

    'flashcards': """Generate {count} FLASHCARD pairs from the content below.

Return as JSON array:
[
  {{"front": "Question or term", "back": "Answer or definition", "difficulty": "easy|medium|hard", "category": "category name"}},
  ...
]

Focus on: key terms, important facts, cause-effect relationships, definitions.

Content:
{content}

Topic: {topic}
""",

    'mcq': """Generate {count} MULTIPLE CHOICE QUESTIONS from the content below.

Return as JSON array:
[
  {{
    "question": "Question text",
    "options": ["A) option", "B) option", "C) option", "D) option"],
    "correct_answer": "A",
    "explanation": "Why this is correct",
    "difficulty": "easy|medium|hard",
    "topic": "subtopic"
  }},
  ...
]

Include a mix of difficulties. Focus on key concepts.

Content:
{content}

Topic: {topic}
""",

    'quiz': """Generate a {difficulty} difficulty QUIZ with {count} questions from the content.

Return as JSON:
{{
  "title": "Quiz title",
  "description": "Brief description",
  "time_limit": minutes (integer),
  "questions": [
    {{
      "question": "Question text",
      "type": "mcq|true_false|short_answer",
      "options": ["option1", "option2", "option3", "option4"],
      "correct_answer": "correct option or answer",
      "explanation": "explanation",
      "points": 1-5,
      "difficulty": "easy|medium|hard"
    }}
  ]
}}

Content:
{content}

Topic: {topic}
""",

    'tutor_response': """You are an intelligent AI tutor helping a student understand their study material.

Study context (from the student's notes):
{context}

Student question: {question}

Provide a helpful, clear explanation. Use examples when appropriate. If the answer is in the notes, reference it. If you're unsure, say so honestly. Keep response focused and educational.
""",
}


class AIService:
    def __init__(self):
        self.provider = settings.AI_PROVIDER
        self.model = settings.AI_MODEL
        self._client = None

    @property
    def client(self):
        if self._client is None:
            self._client = self._init_client()
        return self._client

    def _init_client(self):
        if self.provider == 'openai':
            from openai import OpenAI
            return OpenAI(api_key=settings.OPENAI_API_KEY)

        elif self.provider == 'gemini':
            from google import genai
            return genai.Client(api_key=settings.GEMINI_API_KEY)

        raise ValueError(f'Unsupported AI provider: {self.provider}')

    def generate_text(self, prompt: str, max_tokens: int = None, temperature: float = None) -> str:
        max_tokens = max_tokens or settings.AI_MAX_TOKENS
        temperature = temperature if temperature is not None else settings.AI_TEMPERATURE
        try:
            if self.provider == 'openai':
                response = self.client.chat.completions.create(
                    model=self.model,
                    messages=[
                        {'role': 'system', 'content': 'You are an expert educational AI assistant.'},
                        {'role': 'user', 'content': prompt},
                    ],
                    max_tokens=max_tokens,
                    temperature=temperature,
                )
                return response.choices[0].message.content.strip()
            elif self.provider == 'gemini':
                response = self.client.models.generate_content(
                    model=self.model,       
                    contents=prompt,
                )
                return response.text.strip()
        except Exception as e:
            logger.error(f'AI generation failed: {e}')
            raise

    def generate_notes(self, content: str, note_type: str, topic: str = '', level: str = 'undergraduate') -> str:
        content = content[:4000]

        prompt_template = PROMPTS.get(note_type, PROMPTS['summary'])
        prompt = prompt_template.format(
            content=content,
            topic=topic,
            level=level
        )

        return self.generate_text(prompt)

    def generate_flashcards(self, content: str, topic: str = '', count: int = 10) -> list:
        import json
        prompt = PROMPTS['flashcards'].format(content=content, topic=topic, count=count)
        raw = self.generate_text(prompt)
        return self._parse_json_response(raw, fallback=[])

    def generate_mcqs(self, content: str, topic: str = '', count: int = 10) -> list:
        prompt = PROMPTS['mcq'].format(content=content, topic=topic, count=count)
        raw = self.generate_text(prompt)
        return self._parse_json_response(raw, fallback=[])

    def generate_quiz(self, content: str, topic: str = '', difficulty: str = 'medium', count: int = 10) -> dict:
        prompt = PROMPTS['quiz'].format(
            content=content, topic=topic, difficulty=difficulty, count=count
        )
        raw = self.generate_text(prompt)
        return self._parse_json_response(raw, fallback={'title': topic, 'questions': []})

    def get_tutor_response(self, question: str, context: str = '') -> str:
        prompt = PROMPTS['tutor_response'].format(question=question, context=context)
        return self.generate_text(prompt, temperature=0.5)

    def _parse_json_response(self, raw: str, fallback):
        import json
        import re
        try:
            # Extract JSON from markdown code blocks if present
            match = re.search(r'```(?:json)?\s*([\s\S]*?)\s*```', raw)
            if match:
                raw = match.group(1)
            return json.loads(raw)
        except (json.JSONDecodeError, AttributeError) as e:
            logger.error(f'Failed to parse JSON from AI response: {e}\nRaw: {raw[:200]}')
            return fallback


ai_service = AIService()
