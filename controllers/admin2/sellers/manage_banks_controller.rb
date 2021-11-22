module Admin2::Sellers
  class ManageBanksController < Admin2::AdminBaseController

    before_action :find_bank, except: %i[index new]

    def index
      @banks = @current_community.banks
    end

    def edit
      render layout: false
    end

    def new
      @bank = Bank.new
      render layout: false
    end

    def create
      @bank = Bank.new(bank_params)
      @bank.community = @current_community
      @bank.save!
    rescue StandardError=> e
      flash[:error] = e.message
    ensure
      redirect_to admin2_sellers_manage_banks_path
    end

    def update
      @bank.update!(bank_params)
      flash[:notice] = "Bank info updated successfully."
    rescue StandardError=> e
      flash[:error] = e.message
    ensure
      redirect_to admin2_sellers_manage_banks_path
    end

    def destroy
      @bank.destroy
      flash[:notice] = "Bank deleted successfully."
      redirect_to admin2_sellers_manage_banks_path
    end

    private

    def find_bank
      @bank = @current_community.banks.find_by_id(params[:id])
    end

    def bank_params
      params.require(:bank).permit(:title,:status)
    end

  end
end
