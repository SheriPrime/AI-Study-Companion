# AI Study Companion

A smart, mobile-first educational application designed to streamline student learning by combining robust coursework management with generative AI. Built with Flutter, this app helps students organize their study materials, visually track their academic progress, and leverage AI to instantly generate study aids from their own notes.

## Key Features

*   **AI-Powered Study Hub:** Automatically generates structured summaries and interactive quizzes directly from uploaded lecture materials (PDF and PPT) using the Google Gemini API.
*   **Contextual Video Recommendations:** Suggests relevant YouTube videos based on note topics to enhance visual learning.
*   **Notes Management:** A centralized digital binder to organize and tag study materials by subject.
*   **Study Planner:** Built-in timeline and task management system to keep track of upcoming deadlines and study goals.
*   **Progress Tracking:** Visualizes 7-day study streaks and subject breakdowns using dynamic charts.
*   **Cloud Sync & Authentication:** Secure user authentication and real-time data syncing powered by Firebase and Firestore.

## Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend / Database:** Firebase Authentication, Cloud Firestore, SQLite (for local caching)
*   **AI Integration:** Google Gemini REST API
*   **Key Packages:** `provider` (state management), `fl_chart` (data visualization), `youtube_explode_dart` (video integration)
