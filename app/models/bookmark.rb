# frozen_string_literal: true

class Bookmark < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  belongs_to :topic

  validates :reminder_at, presence: {
    message: I18n.t("bookmarks.errors.time_must_be_provided", reminder_type: I18n.t("bookmarks.reminders.at_desktop")),
    if: -> { reminder_type.present? && reminder_type != Bookmark.reminder_types[:at_desktop] }
  }

  validate :unique_per_post_for_user
  validate :ensure_sane_reminder_at_time

  def unique_per_post_for_user
    existing_bookmark = Bookmark.find_by(user_id: user_id, post_id: post_id)
    return if existing_bookmark.blank? || existing_bookmark.id == id
    self.errors.add(:base, I18n.t("bookmarks.errors.already_bookmarked_post"))
  end

  def ensure_sane_reminder_at_time
    return if reminder_at.blank?
    if reminder_at < Time.now.utc
      self.errors.add(:base, I18n.t("bookmarks.errors.cannot_set_past_reminder"))
    end
    if reminder_at > (Time.now.utc + 10.years)
      self.errors.add(:base, I18n.t("bookmarks.errors.cannot_set_reminder_in_distant_future"))
    end
  end

  def self.reminder_types
    @reminder_type = Enum.new(
      at_desktop: 0,
      later_today: 1,
      next_business_day: 2,
      tomorrow: 3,
      next_week: 4,
      next_month: 5,
      custom: 6
    )
  end
end

# == Schema Information
#
# Table name: bookmarks
#
#  id                    :bigint           not null, primary key
#  user_id               :bigint           not null
#  topic_id              :bigint           not null
#  post_id               :bigint           not null
#  name                  :string
#  reminder_type         :integer
#  reminder_at           :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  reminder_last_sent_at :datetime
#
# Indexes
#
#  index_bookmarks_on_post_id              (post_id)
#  index_bookmarks_on_reminder_at          (reminder_at)
#  index_bookmarks_on_reminder_type        (reminder_type)
#  index_bookmarks_on_topic_id             (topic_id)
#  index_bookmarks_on_user_id              (user_id)
#  index_bookmarks_on_user_id_and_post_id  (user_id,post_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id)
#  fk_rails_...  (topic_id => topics.id)
#  fk_rails_...  (user_id => users.id)
#
