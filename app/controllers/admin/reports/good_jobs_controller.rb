module Admin
  module Reports
    class GoodJobsController < AdminController
      def index
        @queue_and_job_class_statistics = build_queue_and_job_class_statistics
        @slowest_jobs = find_slowest_jobs_per_queue_and_job_class
      end

      private

      def find_slowest_jobs_per_queue_and_job_class
        query = <<-SQL.squish
          select * from (
            select
            row_number() over (partition BY queue_name, serialized_params->>'job_class' ORDER BY (finished_at - performed_at) desc) AS row,
            queue_name,
            serialized_params->>'job_class' as job_class,
            serialized_params->>'job_id' as job_id,
            (finished_at - performed_at) as time_to_completion
            from good_jobs
            group by queue_name, serialized_params->>'job_class', serialized_params->>'job_id', (finished_at - performed_at)
            order by (finished_at - performed_at) desc
          ) jobs
          where jobs.row <= 5
        SQL

        ActiveRecord::Base.connection.execute(query)
      end

      def build_queue_and_job_class_statistics
        query = <<-SQL.squish
          select
          date_trunc('day', created_at) as date,
          queue_name,
          serialized_params->>'job_class' as job_class,
          count(*),
          AVG(finished_at - performed_at),
          MIN(finished_at - performed_at),
          MAX(finished_at - performed_at)
          from good_jobs
          where created_at >= NOW() - INTERVAL '7 days'
          group by date_trunc('day', created_at), queue_name, serialized_params->>'job_class'
          order by date_trunc('day', created_at) desc
        SQL

        ActiveRecord::Base.connection.execute(query)
      end
    end
  end
end
