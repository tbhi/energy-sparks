module Schools
  module Advice
    class SolarPvController < AdviceBaseController
      include AdvicePages

      def insights
      end

      def analysis
      end

      private

      def advice_page_key
        :solar_pv
      end
    end
  end
end