# name: discourse-new-post-notifier
# about: A plugin to notify in previous topic that a new topic has been created by an external embed.
# version: 0.0.1
# authors: Ken Cooper
# url: https://github.com/kcoop/discourse-new-post-notifier

after_initialize do
  DiscourseEvent.on(:topic_created) do | topic, options, user |
    Rails.logger.info("Topic category: #{topic.category}")
    Rails.logger.info("Topic created, maybe notifying, enabled: #{SiteSetting.new_topic_notification_enabled} notifyinguser: #{SiteSetting.new_topic_notifying_user} topic category: #{topic.category.name}")
    # TODO need to detect category is proper, need to map category to category name.

      if SiteSetting.new_topic_notification_enabled && SiteSetting.new_topic_notifying_user.present? then # && topic.category.name == SiteSetting.new_topic_notification_category.strip then
        user_notifying_new_post = User.where(username_lower: SiteSetting.new_topic_notifying_user.strip).first
        Rails.logger.info("User notifying: #{user_notifying_new_post}")
        if user_notifying_new_post then
          last_topic = nil
          Topic.where(category_id: topic.category_id).recent(2) do | existing_topic |
            Rails.logger.info("Checking if topic #{existing_topic_id} matches #{topic.id}")
            if existing_topic.id != topic.id
              last_topic = existing_topic
            end
          end
          if last_topic then
            Rails.logger.info("Last topic: #{last_topic.title}")
            topic_embed = TopicEmbed.where(topic_id: topic.id).first
            if topic_embed then
              Rails.logger.info("Topic embed: #{topic_embed}")
              embed_url = topic_embed.embed_url
              raw = SiteSetting.new_topic_raw_body
              raw = raw.sub('{blog_new_topic_url}', embed_url)
              raw = raw.sub('{title}', topic.title)
              raw = raw.sub('{discourse_new_topic_url}', topic.url)
              creator = PostCreator.new(user_notifying_new_post, topic_id: last_topic.id, raw: raw)
              creator.create
            else
              Rails.logger.info("Could not find topic embed for topic id: #{topic.id}")
            end
          else
            Rails.logger.info("Could not find previous topic in category: #{SiteSetting.new_topic_notification_category}")
          end
        else
          Rails.logger.info("Could not find matching user to assign as notifier: #{SiteSetting.new_topic_notifying_user}")
        end
      end
  end
end