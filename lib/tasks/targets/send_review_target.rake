namespace :targets do
  desc 'Send email to set new target'
  task send_review_target: [:environment] do
    puts "#{Time.zone.now} Sending set new target emails"
    Targets::TargetMailerService.new.invite_schools_to_review_target
    puts "#{Time.zone.now} Finished sending set new target emails"
  end
end