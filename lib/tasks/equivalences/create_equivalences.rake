namespace :equivalences do
  desc 'Run equivalences job'
  task create: [:environment] do
    puts Time.zone.now
    schools = School.with_config
    schools.each do |school|
      begin
        puts "Running all equivalences for #{school.name}"
        Equivalences::GenerateEquivalences.new(school, EnergyConversions).perform
      rescue => e
        Rails.logger.error("#{e.message} for #{school.name}")
        Rollbar.error(e)
      end

    end
    puts Time.zone.now
  end
end
