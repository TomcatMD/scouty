# frozen_string_literal: true

module Scouty
  class Registry
    Report = Data.define(:company, :position, :score, :notes, :scored_at)

    attr_reader :db

    def initialize(file:)
      @db = SQLite3::Database.new(file)

      @db.execute(<<~SQL)
        CREATE TABLE IF NOT EXISTS "jobs" (
          "url"	TEXT NOT NULL,
          "company"	TEXT,
          "position"	TEXT,
          "score"	NUMERIC,
          "notes"	TEXT,
          "created_at"	TEXT NOT NULL,
          "updated_at"	TEXT NOT NULL,
          "scored_at"	TEXT,
          "deleted_at"	TEXT,
          PRIMARY KEY("url")
        )
      SQL
    end

    def list_urls
      db.execute("SELECT url FROM jobs WHERE deleted_at IS NULL").map(&:first)
    end

    def register_url(url)
      now = current_time

      db.execute(<<~SQL, [url, now, now, now])
        INSERT INTO jobs(url, created_at, updated_at)
        VALUES (?, ?, ?)
        ON CONFLICT(url)
        DO UPDATE SET updated_at = ?, deleted_at = NULL
      SQL
    end

    def unregister_url(url)
      db.execute(
        "UPDATE jobs SET deleted_at = ? WHERE url = ?",
        [current_time, url]
      )
    end

    def find_unscored_url
      result = db.execute(<<~SQL)
        SELECT url FROM jobs
        WHERE score IS NULL
        AND deleted_at IS NULL
        LIMIT 1
      SQL

      result.first&.first
    end

    def submit_report(url, analysis)
      sets = [
        "company = ?",
        "position = ?",
        "score = ?",
        "notes = ?",
        "scored_at = ?"
      ]

      params = [
        analysis.company,
        analysis.position,
        analysis.score,
        analysis.notes,
        current_time
      ]

      params << url

      db.execute("UPDATE jobs SET #{sets.join(", ")} WHERE url = ?", params)
    end

    def find_report(url)
      result =
        db.execute(<<~SQL, url)
          SELECT company, position, score, notes, scored_at
          FROM jobs
          WHERE url = ?
          AND score IS NOT NULL
          AND deleted_at IS NULL
        SQL

      return if result.empty?

      Report.new(*result.first)
    end

    private

    def current_time
      DateTime.now.iso8601(3)
    end
  end
end
