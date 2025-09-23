# Scouty

**Scouty** is your personal assistant for reviewing job postings and evaluating their relevance to your professional profile. It crawls popular job boards, analyzes postings with a **local LLM**, and scores them based on your skills, experience, and preferences.

## ✨ Features

- 🔍 **Multi-source crawling** – Supports [Just Join IT](https://justjoin.it), [No Fluff Jobs](https://nofluffjobs.com), and [RemoteOK](https://remoteok.com).
- 🤖 **Local LLM analysis** – Uses `gpt-oss-20b` via [LM Studio](https://lmstudio.ai) (no API keys required).
- 📊 **Relevance scoring** – Rates jobs from `0.0` to `5.0` with a brief explanation.
- 💾 **Persistent storage** – Saves all results in a lightweight `SQLite` database (`data/jobs.db`).
- 📲 **Telegram notifications** – Instant alerts about new hot matches via Telegram.

## 🚀 Getting Started

### 1. Prerequisites

- [LM Studio](https://lmstudio.ai) installed
- `openai/gpt-oss-20b` model downloaded in LM Studio
- Ruby **3.4.5+** (install via [asdf](https://asdf-vm.com); a `.tool-versions` file is included)

### 2. Install Dependencies

```sh
bundle install
```

### 3. Prepare Your Profile

To tailor job recommendations, copy the example configuration file `config.example.yml` to `config.yml` and update the parameters to reflect your skills, experience, and preferences. Refer to the comments in `config.yml` for guidance on each parameter.

```sh
cp config.example.yml config.yml
```

### 4. Run Scouty

```sh
bin/scouty
```

### 5. Review Results

By default, Scouty generates an HTML report at `data/report.html` for easy viewing of your job matches and analysis results. Simply open this file in your web browser.

```sh
open data/report.html
```

For more detailed inspection, you can also review the raw data in the SQLite database using tools such as:

- [DB Browser for SQLite](https://sqlitebrowser.org)
- The built-in SQLite CLI:

```sh
sqlite3 data/jobs.db
```

## 📄 License

This project is licensed under the [MIT License](./LICENSE). Feel free to use, modify, and share.

## 💡 Tips

- Ensure LM Studio is running while using Scouty to process job postings.
- The analysis process may take some time, depending on the number of job postings and system resources.
- Run `bin/scouty --help` to view available parameters for running.
- Check `data/jobs.db` regularly to review new job matches and clear old data if needed.
