class CheckoutsController < ApplicationController
  TRANSACTION_SUCCESS_STATUSES = [
    Braintree::Transaction::Status::Authorizing,
    Braintree::Transaction::Status::Authorized,
    Braintree::Transaction::Status::Settled,
    Braintree::Transaction::Status::SettlementConfirmed,
    Braintree::Transaction::Status::SettlementPending,
    Braintree::Transaction::Status::Settling,
    Braintree::Transaction::Status::SubmittedForSettlement,
  ]

  def client_token
    @client_token = Braintree::ClientToken.generate
    # puts @client_token
    render json: @client_token
  end

  def new
     @client_token = Braintree::ClientToken.generate
	   puts @client_token
  end

  def show
    @transaction = Braintree::Transaction.find(params[:id])
	  # puts @transaction
    @result = _create_result_hash(@transaction)
  end

  def checkout
    amount = params["amount"] # In production you should not take amounts directly from clients
    nonce = params["payment_method_nonce"]
    email = params["email"]
    # puts email
    # user = User.find_by email: email
    # puts user
    # if user === nil 
    if not User.where(email: email).exists?
      puts json:'user_no_exist'
      result = Braintree::Transaction.sale(
          amount: amount,
          payment_method_nonce: nonce,
          :options => {
            :submit_for_settlement => true
          }
        )
      if result.success? || result.transaction
        puts "success"
        User.find_or_create_by(email: email)
        # render json:result.transaction.id
        @transaction = Braintree::Transaction.find(result.transaction.id)
        # render @transaction
        # puts @transaction.methods
        render json:result.transaction.id
      else
        # puts "fail"
        render :json => { :errors => makeFailureResponse}, :status => 422

      end
    else
      render :json => { :errors => makeUserExistResponse}, :status => 420
    end
  end

  def makeUserExistResponse
    @response = {}
    @response['responseCode'] = 420
    @response['response'] = 'user_exist'
    return @response.to_json
  end

  def makeFailureResponse
    @response = {}
    @response['responseCode'] = 422
    @response['response'] = 'transaction_failure'
    return @response.to_json
  end

  def create
    amount = params["amount"] # In production you should not take amounts directly from clients
    nonce = params["payment_method_nonce"]

    result = Braintree::Transaction.sale(
      amount: amount,
      payment_method_nonce: nonce,
      :options => {
        :submit_for_settlement => true
      }
    )

    if result.success? || result.transaction
      redirect_to checkout_path(result.transaction.id)
    else
      error_messages = result.errors.map { |error| "Error: #{error.code}: #{error.message}" }
      flash[:error] = error_messages
      redirect_to new_checkout_path
    end
  end

  def _create_result_hash(transaction)
    status = transaction.status

    if TRANSACTION_SUCCESS_STATUSES.include? status
      result_hash = {
        :header => "Sweet Success!",
        :icon => "success",
        :message => "Your test transaction has been successfully processed. See the Braintree API response and try again."
      }
    else
      result_hash = {
        :header => "Transaction Failed",
        :icon => "fail",
        :message => "Your test transaction has a status of #{status}. See the Braintree API response and try again."
      }
    end
  end
end
