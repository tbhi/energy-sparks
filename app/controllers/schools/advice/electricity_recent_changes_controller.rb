module Schools
  module Advice
    class ElectricityRecentChangesController < AdviceBaseController
      include AdvicePages

      def insights
      end

      def analysis
      end

      private

      def advice_page_key
        :electricity_recent_changes
      end
    end
  end
end