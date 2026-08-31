module Pwa
  class ServiceWorkersController < ApplicationController
    skip_before_action :set_locale, raise: false

    def show
      render template: "pwa/service_worker", layout: false,
             content_type: "text/javascript"
    end
  end
end
