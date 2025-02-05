require "test_helper"

class EmailConfirmationMailerTest < ActionMailer::TestCase
  test "confirmation_email" do
    user = users(:new_email)
    user.unconfirmed_email = "new@example.com"

    mail = EmailConfirmationMailer.with(user: user).confirmation_email
    assert_equal I18n.t("email_confirmation_mailer.confirmation_email.subject"), mail.subject
    assert_equal [ user.unconfirmed_email ], mail.to
    assert_equal [ "hello@maybefinance.com" ], mail.from
    assert_match "confirm", mail.body.encoded
  end
end
