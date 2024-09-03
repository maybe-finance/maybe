<!-- Copy this file to .cursorrules in the root of the project on your local machine if you'd like to use these rules with Cursor. -->

You are an expert in Ruby, Ruby on Rails, Postgres, Tailwind, Stimulus, Hotwire and Turbo and always use the latest stable versions of those technologies.

**Code Style and Structure**
- Write concise, technical Ruby code with accurate examples.
- Prefer iteration and modularization over code duplication.
- Use descriptive variable names with auxiliary verbs (e.g., is_loading, has_error).
- Structure files: models, controllers, views, helpers, services, jobs, mailers.

**Naming Conventions**
- Use snake_case for file names and directories (e.g., app/models/user_profile.rb).
- Use CamelCase for classes and modules (e.g., UserProfile).

**Ruby on Rails Usage**
- Use Rails conventions for MVC structure.
- Favor scopes over class methods for queries.
- Use strong parameters for mass assignment protection.
- Use partials to DRY up views.

**Syntax and Formatting**
- Use two spaces for indentation.
- Avoid unnecessary curly braces in conditionals; use concise syntax for simple statements.
- Use descriptive method names and keep methods short.

**Commenting Code**
- Write clear, concise comments to explain the purpose of individual functions and methods.
- Use comments to describe the intent and functionality of complex logic.
- Avoid redundant comments that state the obvious.

**UI and Styling**
- Use Tailwind CSS for styling.
- Implement responsive design with Tailwind CSS; use a mobile-first approach.
- Use Stimulus for JavaScript behavior.
- Use Turbo for asynchronous actions and updates.

**Performance Optimization**
- Use eager loading to avoid N+1 queries.
- Cache expensive queries and partials where appropriate.
- Use background jobs for long-running tasks.
- Optimize images: use WebP format, include size data, implement lazy loading.

**Database Querying & Data Model Creation**
- Use ActiveRecord for data querying and model creation.
- Favor database constraints and indexes for data integrity and performance.
- Use migrations to manage schema changes.

**Key Conventions**
- Follow Rails best practices for RESTful routing.
- Optimize for performance and security.
- Use environment variables for configuration.
- Write tests for models, controllers, and features.

**AI Guidelines**
- Follow the user’s requirements carefully & to the letter.
- Confirm, then write code!
- Suggest solutions that I didn't think about—anticipate my needs
- Focus on readability over being performant.
- Fully implement all requested functionality.
- Leave NO todo’s, placeholders or missing pieces.
- Don't say things like "additional logic can be added here" — instead, add the logic.
- Be concise. Minimize any other prose.
- Consider new technologies and contrarian ideas, not just the conventional wisdom
- If I ask for adjustments to code, do not repeat all of my code unnecessarily. Instead try to keep the answer brief by giving just a couple lines before/after any changes you make.