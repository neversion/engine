module Locomotive
  class InstallationController < ::ApplicationController

    layout '/locomotive/layouts/not_logged_in'

    before_filter :is_step_already_done?

    before_filter :allow_installation?

    before_filter :set_content_locale

    helper Locomotive::BaseHelper, Locomotive::SitesHelper

    def show
      request.get? ? self.handle_get : self.handle_post
    end

    private

    def handle_get
      case params[:step].to_i
      when 1 then @account = Account.new
      when 2 then @site = Site.new
      end
      render "step_#{params[:step]}"
    end

    def handle_post
      case params[:step].to_i
      when 1 # create account
        @account = Account.create(params[:account].merge(super_admin: true))
        if @account.valid?
          redirect_to installation_step_url(2)
        else
          render 'step_1'
        end
      when 2 # create site
        @site = Site.create_first_one(params[:site])

        if @site.valid?
          redirect_to last_url
        else
          logger.error "Unable to create the first website: #{@site.errors.inspect}"
          render 'step_2'
        end
      end
    end

    def is_step_already_done?
      case params[:step].to_i
      when 1 # already an account in db
        if account = Account.first
          @step_done = I18n.t('locomotive.installation.step_1.done', name: account.name, email: account.email)
          render 'step_1' and return false
        end
      else
        true
      end
    end

    def allow_installation?
      redirect_to pages_url if Site.count > 0 && Account.count > 0
    end

    def set_content_locale
      locale = params[:site].try(:[], :locales).try(:first) || Locomotive.config.site_locales.first
      ::Mongoid::Fields::I18n.locale = locale
      ::Mongoid::Fields::I18n.fallbacks_for(locale, Locomotive.config.site_locales)
    end

    def last_url
      if Locomotive.config.manage_domains?
        locomotive_account_session_url(host: Site.first.domains.first, port: request.port)
      else
        locomotive_account_session_url
      end
    end

  end
end
