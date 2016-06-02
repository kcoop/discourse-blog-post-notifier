# name: discourse-new-post-notifier
# about: A plugin to notify in previous topic that a new topic has been created by an external embed.
# version: 0.0.1
# authors: Ken Cooper
# url: https://github.com/kcoop/discourse-new-post-notifier

after_initialize do
  DiscourseEvent.on(:topic_created) do | topic, options, user |
      if SiteSetting.new_topic_notification_enabled && SiteSetting.new_topic_notifying_user.present? && topic.category.name == SiteSetting.new_topic_notification_category.strip then
        user_notifying_new_post = User.where(username_lower: SiteSetting.new_topic_notifying_user.strip).first
        if user_notifying_new_post then
          # If there's only one topic in this category, it's the new one, don't notify
          two_most_recent_topics_in_category = Topic.where(category_id: topic.category.id).recent(2)
          if two_most_recent_topics_in_category.count == 2
            last_topic = two_most_recent_topics_in_category.last
            topic_embed = TopicEmbed.where(topic_id: topic.id).first
            if topic_embed then
              embed_url = topic_embed.embed_url
              raw = SiteSetting.new_topic_raw_body
              raw = raw.sub('{blog_new_topic_url}', embed_url)
              raw = raw.sub('{title}', topic.title)
              raw = raw.sub('{discourse_new_topic_url}', topic.url)
              creator = PostCreator.new(user_notifying_new_post, topic_id: last_topic.id, raw: raw)
              creator.create
              Rails.logger.info("Notified of new topic '#{topic.title}' in topic '#{last_topic.title}'")
            else
              Rails.logger.error("Could not find topic embed for topic id: #{topic.id}")
            end
          else
            Rails.logger.info("No previous topic in category #{SiteSetting.new_topic_notification_category}, not notifying")
          end
        else
          Rails.logger.info("Could not find matching user to assign as notifier: #{SiteSetting.new_topic_notifying_user}")
        end
      end
  end
end