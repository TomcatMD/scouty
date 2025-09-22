# frozen_string_literal: true

module Scouty
  class Registry
    Review = Data.define(:company, :position, :score, :notes, :scored_at)

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

    def submit_review(url, review)
      sets = [
        "company = ?",
        "position = ?",
        "score = ?",
        "notes = ?",
        "scored_at = ?"
      ]

      params = [
        review.company,
        review.position,
        review.score,
        review.notes,
        current_time
      ]

      params << url

      db.execute("UPDATE jobs SET #{sets.join(", ")} WHERE url = ?", params)
    end

    def find_review(url)
      result =
        db.execute(<<~SQL, url)
          SELECT company, position, score, notes, scored_at
          FROM jobs
          WHERE url = ?
          AND score IS NOT NULL
          AND deleted_at IS NULL
        SQL

      return if result.empty?

      Review.new(*result.first)
    end

    def generate_report
      Report.build(db:)
    end

    private

    def current_time
      DateTime.now.iso8601(3)
    end

    class Report
      Company = Data.define(:name, :top_job_score, :jobs)
      Job = Data.define(:url, :position, :score, :notes)

      def self.build(db:)
        records =
          db.execute(<<~SQL)
            WITH ranked_jobs AS (
              SELECT
                ROW_NUMBER() OVER (
                  PARTITION BY company, position
                  ORDER BY score DESC, created_at DESC
                ) AS rank,
                *
              FROM jobs
              WHERE score >= 0.0
              AND company IS NOT NULL
              AND company <> ''
              AND deleted_at IS NULL
            )

            SELECT url, company, position, score, notes FROM ranked_jobs
            WHERE rank = 1
            ORDER BY score DESC
          SQL

        new(records:)
      end

      attr_reader :companies

      def initialize(records:)
        @companies = build_companies(records:)
      end

      private

      def build_companies(records:)
        records
          .group_by { |i| i[1] }
          .map { |name, group| build_company(name:, records: group) }
      end

      def build_company(name:, records:)
        jobs = records.map { |r| build_job(record: r) }

        Company.new(
          name:,
          top_job_score: jobs.map(&:score).max,
          jobs: jobs
        )
      end

      def build_job(record:)
        Job.new(
          url: record[0],
          position: record[2],
          score: record[3].to_f,
          notes: record[4]
        )
      end
    end
  end
end
