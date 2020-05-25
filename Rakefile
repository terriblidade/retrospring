# frozen_string_literal: true

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

namespace :justask do
  desc "Regenerate themes"
  task themes: :environment do
    format = '%t (%c/%C) [%b>%i] %e'

    all = Theme.all

    progress = ProgressBar.create title: 'Processing themes', format: format, starting_at: 0, total: all.count

    all.each do |theme|
      theme.touch
      theme.save!
      progress.increment
    end

    puts "regenerated #{all.count} themes"
  end

  desc "Upload to AWS"
  task paperclaws: :environment do
    if APP_CONFIG["fog"]["credentials"].nil? or APP_CONFIG["fog"]["credentials"]["provider"] != "AWS"
      throw "Needs fog (AWS) to be defined in justask.yml"
    end

    format = '%t (%c/%C) [%b>%i] %e'
    root = "#{Rails.root}/public/system"
    files = Dir["#{root}/**/*.*"]
    progress = ProgressBar.create title: 'Processing files', format: format, starting_at: 0, total: files.length

    # weird voodoo, something is causing just using "APP_CONFIG["fog"]["credentials"]" as Fog::Storage.new to cause an exception
    # TODO: Programmatically copy?
    credentials = {
      provider: "AWS",
      aws_access_key_id: APP_CONFIG["fog"]["credentials"]["aws_access_key_id"],
      aws_secret_access_key: APP_CONFIG["fog"]["credentials"]["aws_secret_access_key"],
      region: APP_CONFIG["fog"]["credentials"]["region"]
    }

    fog = Fog::Storage.new credentials
    bucket = fog.directories.get APP_CONFIG["fog"]["directory"]

    files.each do |file|
      bucket.files.create key: file[root.length + 1 ... file.length], body: File.open(file), public: true
      progress.increment
    end

    puts "hopefully uploaded #{files.length} files"
  end

  desc "Recount everything!"
  task recount: :environment do
    puts "Processing users..."
    ActiveRecord::Base.connection.execute <<~SQL
      update users set
        friend_count         = (select count(*) from relationships  where source_id = users.id),
        follower_count       = (select count(*) from relationships  where target_id = users.id),
        asked_count          = (select count(*) from questions      where user_id   = users.id and author_name is null and author_is_anonymous = false),
        answered_count       = (select count(*) from answers        where user_id   = users.id),
        commented_count      = (select count(*) from comments       where user_id   = users.id),
        smiled_count         = (select count(*) from smiles         where user_id   = users.id),
        comment_smiled_count = (select count(*) from comment_smiles where user_id   = users.id);
    SQL

    puts "Processing questions..."
    ActiveRecord::Base.connection.execute <<~SQL
      update questions set
        answer_count = (select count(*) from answers where question_id = questions.id);
    SQL

    puts "Processing answers..."
    ActiveRecord::Base.connection.execute <<~SQL
      update answers set
        comment_count = (select count(*) from comments where answer_id = answers.id),
        smile_count   = (select count(*) from smiles where answer_id = answers.id);
    SQL

    puts "Processing comments..."
    ActiveRecord::Base.connection.execute <<~SQL
      update comments set
        smile_count = (select count(*) from comment_smiles where comment_id = comments.id);
    SQL
  end

  desc "Gives admin status to a user."
  task :admin, [:screen_name] => :environment do |t, args|
    abort "screen name required" if args[:screen_name].nil?

    user = User.find_by_screen_name(args[:screen_name])
    abort "user #{args[:screen_name]} not found" if user.nil?

    user.add_role :administrator
    puts "#{user.screen_name} is now an administrator."
  end

  desc "Removes admin status from a user."
  task :deadmin, [:screen_name] => :environment do |t, args|
    abort "screen name required" if args[:screen_name].nil?

    user = User.find_by_screen_name(args[:screen_name])
    abort "user #{args[:screen_name]} not found" if user.nil?

    user.remove_role :administrator
    puts "#{user.screen_name} is no longer an administrator."
  end

  desc "Gives moderator status to a user."
  task :mod, [:screen_name] => :environment do |t, args|
    abort "screen name required" if args[:screen_name].nil?

    user = User.find_by_screen_name(args[:screen_name])
    abort "user #{args[:screen_name]} not found" if user.nil?

    user.add_role :moderator
    puts "#{user.screen_name} is now a moderator."
  end

  desc "Removes moderator status from a user."
  task :demod, [:screen_name] => :environment do |t, args|
    abort "screen name required" if args[:screen_name].nil?

    user = User.find_by_screen_name(args[:screen_name])
    abort "user #{args[:screen_name]} not found" if user.nil?

    user.remove_role :moderator
    puts "#{user.screen_name} is no longer a moderator."
  end

  desc "Hits an user with the banhammer."
  task :permanently_ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    fail "user #{args[:screen_name]} not found" if user.nil?
    user.permanently_banned = true
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Hits an user with the banhammer for one day."
  task :ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    user.permanently_banned = false
    user.banned_until = DateTime.current + 1
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Hits an user with the banhammer for one week."
  task :week_ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    user.permanently_banned = false
    user.banned_until = DateTime.current + 7
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Hits an user with the banhammer for one month."
  task :month_ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    user.permanently_banned = false
    user.banned_until = DateTime.current + 30
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Hits an user with the banhammer for one year."
  task :year_ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    user.permanently_banned = false
    user.banned_until = DateTime.current + 365
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Hits an user with the banhammer for one aeon."
  task :aeon_ban, [:screen_name, :reason] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    user.permanently_banned = false
    user.banned_until = DateTime.current + 365_000_000_000
    user.ban_reason = args[:reason]
    user.save!
    puts "#{user.screen_name} got hit by\033[5m YE OLDE BANHAMMER\033[0m!!1!"
  end

  desc "Removes banned status from an user."
  task :unban, [:screen_name] => :environment do |t, args|
    fail "screen name required" if args[:screen_name].nil?
    user = User.find_by_screen_name(args[:screen_name])
    fail "user #{args[:screen_name]} not found" if user.nil?
    user.permanently_banned = false
    user.banned_until = nil
    user.ban_reason = nil
    user.save!
    puts "#{user.screen_name} is no longer banned."
  end

  desc "Lists all users."
  task lusers: :environment do
    User.all.each do |u|
      puts "#{sprintf "%3d", u.id}. #{u.screen_name}"
    end
  end

  desc "Fixes the notifications"
  task fix_notifications: :environment do
    format = '%t (%c/%C) [%b>%i] %e'
    total = Notification.count
    progress = ProgressBar.create title: 'Processing notifications', format: format, starting_at: 0, total: total
    destroyed_count = 0

    Notification.all.each do |n|
      if n.target.nil?
        n.destroy
        destroyed_count += 1
      end
      progress.increment
    end

    puts "Purged #{destroyed_count} dead notifications."
  end

  desc "Subscribes everyone to their answers"
  task fix_submarines: :environment do
    format = '%t (%c/%C) [%b>%i] %e'

    total = Answer.count
    progress = ProgressBar.create title: 'Processing answers', format: format, starting_at: 0, total: total
    subscribed = 0

    Answer.all.each do |a|
      if not a.user.nil?
        Subscription.subscribe a.user, a
        subscribed += 1
      end

      progress.increment
    end

    puts "Subscribed to #{subscribed} posts."
  end

  desc "Destroy lost subscriptions"
  task fix_torpedoes: :environment do
    format = '%t (%c/%C) [%b>%i] %e'

    total = Subscription.count
    progress = ProgressBar.create title: 'Processing subscriptions', format: format, starting_at: 0, total: total
    destroyed = 0
    Subscription.all.each do |s|
      if s.user.nil? or s.answer.nil?
        s.destroy
        destroyed += 1
      end

      progress.increment
    end

    puts "Put #{destroyed} subscriptions up for adoption."
  end

  desc "Fixes reports"
  task fix_reports: :environment do
    format = '%t (%c/%C) [%b>%i] %e'

    total = Report.count
    progress = ProgressBar.create title: 'Processing reports', format: format, starting_at: 0, total: total
    destroyed = 0
    Report.all.each do |r|
      if r.target.nil? and not r.deleted?
        r.deleted = true
        r.save
        destroyed += 1
      elsif r.user.nil?
        r.destroy
        destroyed += 1
      end
      progress.increment
    end

    puts "Marked #{destroyed} reports as deleted."
  end

  desc "Fixes everything else"
  task fix_db: :environment do
    format = '%t (%c/%C) [%b>%i] %e'
    destroyed_count = {
        inbox: 0,
        question: 0,
        answer: 0,
        smile: 0,
        comment: 0,
        subscription: 0,
        report: 0
    }

    total = Inbox.count
    progress = ProgressBar.create title: 'Processing inboxes', format: format, starting_at: 0, total: total
    Inbox.all.each do |n|
      if n.question.nil?
        n.destroy
        destroyed_count[:inbox] += 1
      end
      progress.increment
    end

    total = Question.count
    progress = ProgressBar.create title: 'Processing questions', format: format, starting_at: 0, total: total
    Question.all.each do |q|
      if q.user.nil?
        q.user_id = nil
        q.author_is_anonymous = true
        destroyed_count[:question] += 1
      end
      progress.increment
    end

    total = Answer.count
    progress = ProgressBar.create title: 'Processing answers', format: format, starting_at: 0, total: total
    Answer.all.each do |a|
      if a.user.nil? or a.question.nil?
        a.destroy
        destroyed_count[:answer] += 1
      end
      progress.increment
    end

    total = Comment.count
    progress = ProgressBar.create title: 'Processing comments', format: format, starting_at: 0, total: total
    Comment.all.each do |c|
      if c.user.nil? or c.answer.nil?
        c.destroy
        destroyed_count[:comment] += 1
      end
      progress.increment
    end

    total = Subscription.count
    progress = ProgressBar.create title: 'Processing subscriptions', format: format, starting_at: 0, total: total
    Subscription.all.each do |s|
      if s.user.nil? or s.answer.nil?
        s.destroy
        destroyed_count[:subscription] += 1
      end

      progress.increment
    end

    total = Report.count
    progress = ProgressBar.create title: 'Processing reports', format: format, starting_at: 0, total: total
    Report.all.each do |r|
      if r.target.nil? and not r.deleted?
        r.deleted = true
        r.save
        destroyed_count[:report] += 1
      elsif r.user.nil?
        r.destroy
        destroyed_count[:report] += 1
      end
      progress.increment
    end

    puts "Put #{destroyed_count[:subscription]} subscriptions up for adoption."
    puts "Purged #{destroyed_count[:inbox]} dead inbox entries."
    puts "Marked #{destroyed_count[:question]} questions as anonymous."
    puts "Purged #{destroyed_count[:answer]} dead answers."
    puts "Purged #{destroyed_count[:comment]} dead comments."
    puts "Purged #{destroyed_count[:subscription]} dead subscriptions."
    puts "Marked #{destroyed_count[:report]} reports as deleted."
  end

  desc "Prints lonely people."
  task loners: :environment do
    Answer.find_by_sql(<<~SQL).each do |a|
      select answers.id, answers.user_id
      from answers
      inner join questions on answers.question_id = questions.id
      inner join users     on answers.user_id     = users.id
      where (questions.author_is_anonymous = true)
      and (questions.author_name is null)
      and (answers.user_id = questions.user_id)
      order by users.screen_name, answers.id;
    SQL
      puts "#{a.user.screen_name} -- answer id #{a.id}"
    end

    loner_counts = ActiveRecord::Base.connection.execute <<~SQL
      select users.screen_name, count(*)
      from answers
      inner join questions on answers.question_id = questions.id
      inner join users     on answers.user_id     = users.id
      where (questions.author_is_anonymous = true)
        and (questions.author_name is null)
        and (answers.user_id = questions.user_id)
      group by users.screen_name
      order by count desc;
    SQL

    max_count = loner_counts.map { |res| res["count"] }.max
    res = loner_counts.select { |res| res["count"] == max_count }.map { |res| res["screen_name"] }

    if res.length == 0
      puts "No one?  I hope you're just on the development session."
    else
      puts res.length == 1 ? "And the winner is..." : "And the winners are..."
      print "\033[5;31m"
      res.each { |name| puts " - #{name}" }
      print "\033[0m"
    end
  end
end
