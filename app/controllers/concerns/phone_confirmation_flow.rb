module PhoneConfirmationFlow
  extend ActiveSupport::Concern

  def show
    raise 'must override'
  end

  def send_code
    send_confirmation_code
    redirect_to this_phone_confirmation_path
  end

  def confirm
    if params['code'] == confirmation_code
      analytics.track_event('User confirmed their phone number')
      process_valid_code
    else
      analytics.track_event('User entered invalid phone confirmation code')
      process_invalid_code
    end
  end

  private

  def generate_confirmation_code
    digits = Devise.direct_otp_length
    random_base10(digits)
  end

  def random_base10(digits)
    SecureRandom.random_number(10**digits).to_s.rjust(digits, '0')
  end

  def process_invalid_code
    flash[:error] = t('errors.invalid_confirmation_code')
    redirect_to this_phone_confirmation_path
  end

  def process_valid_code
    assign_phone
    clear_session_data

    flash[:success] = t('notices.phone_confirmation_successful')
    redirect_to after_confirmation_path
  end

  def this_phone_confirmation_path
    raise 'must override'
  end

  def assign_phone
    raise 'must override'
  end

  def after_confirmation_path
    raise 'must override'
  end

  def check_for_unconfirmed_phone
    redirect_to root_path unless unconfirmed_phone
  end

  def send_confirmation_code
    # Generate a new confirmation code only if there isn't already one set in the
    # user's session. Re-sending the confirmation code doesn't generate a new one.
    self.confirmation_code = generate_confirmation_code unless confirmation_code

    SmsSenderOtpJob.perform_later(confirmation_code, unconfirmed_phone)
  end

  def confirmation_code=(code)
    user_session[confirmation_code_session_key] = code
  end

  def confirmation_code
    user_session[confirmation_code_session_key]
  end

  def unconfirmed_phone
    user_session[unconfirmed_phone_session_key]
  end

  def clear_session_data
    user_session.delete(unconfirmed_phone_session_key)
    user_session.delete(confirmation_code_session_key)
  end
end
