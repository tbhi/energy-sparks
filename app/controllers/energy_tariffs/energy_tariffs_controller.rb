module EnergyTariffs
  class EnergyTariffsController < ApplicationController
    include Adminable
    include EnergyTariffable
    include EnergyTariffsHelper

    load_and_authorize_resource :school, instance_name: 'tariff_holder'
    load_and_authorize_resource :school_group, instance_name: 'tariff_holder'
    load_and_authorize_resource :energy_tariff
    before_action :admin_authorized?, if: :site_settings_resource?
    before_action :load_site_setting, if: :site_settings_resource?
    before_action :set_breadcrumbs

    def index
      authorize! :manage, @tariff_holder.energy_tariffs.build

      if @tariff_holder.school?
        @electricity_meters = @tariff_holder.meters.electricity
        @gas_meters = @tariff_holder.meters.gas
      end
    end

    def new
      @energy_tariff = if @tariff_holder.school?
                         @tariff_holder.energy_tariffs.build(energy_tariff_params.merge(default_params))
                       else
                         @tariff_holder.energy_tariffs.build(meter_type: params[:meter_type])
                       end

      if require_meters?
        redirect_back fallback_location: school_energy_tariffs_path(@tariff_holder), notice: I18n.t('schools.user_tariffs.choose_meters.missing_meters')
      end
    end

    def create
      @energy_tariff = @tariff_holder.energy_tariffs.build(energy_tariff_params.merge(created_by: current_user))
      if @energy_tariff.save
        if @energy_tariff.gas?
          redirect_to_energy_tariff_prices_path
        else
          redirect_to_choose_type_energy_tariff_path
        end
      else
        render :new
      end
    end

    def choose_meters
      if params[:meter_type] == 'electricity'
        @meters = @tariff_holder.meters.electricity
      elsif params[:meter_type] == 'gas'
        @meters = @tariff_holder.meters.gas
      else
        @meters = []
      end
    end

    def choose_type
    end

    def update
      if @energy_tariff.update(energy_tariff_params.merge(updated_by: current_user))
        EnergyTariffDefaultPricesCreator.new(@energy_tariff).process
        redirect_to energy_tariffs_path(@energy_tariff, [:energy_tariff_prices])
      else
        render :edit
      end
    end

    def show
    end

    def destroy
      redirect_path = energy_tariffs_path(@energy_tariff, [], { energy_tariff_index: true })
      @energy_tariff.destroy
      redirect_to redirect_path
    end

    private

    def require_meters?
      params[:specific_meters] && @energy_tariff.meter_ids.empty? && @tariff_holder.school?
    end

    def redirect_to_choose_type_energy_tariff_path
      redirect_to energy_tariffs_path(@energy_tariff, [], { action: :choose_type })
    end

    def redirect_to_energy_tariff_prices_path
      redirect_to energy_tariffs_path(@energy_tariff, [:energy_tariff_prices])
    end

    def set_breadcrumbs
      @breadcrumbs = [{ name: I18n.t('manage_school_menu.manage_tariffs') }]
    end

    def default_params
      { start_date: Date.parse('2021-04-01'), end_date: Date.parse('2022-03-31'), tariff_type: :flat_rate }
    end

    def energy_tariff_params
      params.require(:energy_tariff).permit(:meter_type, :name, :start_date, :end_date, :tariff_type, :vat_rate, meter_ids: [])
    end
  end
end
