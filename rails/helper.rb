require_library_or_gem 'action_pack'
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module AuthorizeNetSim
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          # Replace with the real mapping
          
          
          mapping :account, 'x_login'
          mapping :amount, 'x_amount'
          
          mapping :order, 'x_fp_sequence'

          mapping :customer, :first_name => 'x_first_name',
                             :last_name  => 'x_last_name',
                             :email      => 'x_email',
                             :phone      => 'x_phone'

          mapping :billing_address, :city     => 'x_city',
                                    :address1 => 'x_address',
                                    :address2 => '',# TODO :)
                                    :state    => 'x_state',
                                    :zip      => 'x_zip',
                                    :country  => 'x_country'

          mapping :notify_url, 'x_relay_url'
          mapping :return_url, ''
          mapping :cancel_return_url, ''
          
          # custom ones for ANS ==>
          # see http://www.authorize.net/support/SIM_guide.pdf for detailed descriptions
          mapping :fax, 'x_fax'
          mapping :customer_id, 'x_cust_id'
          mapping :description, 'x_description' # This one isn't even shown to the user unless you specifically set it up to be
          # these next two ignored by AN, believe it or not
          mapping :tax, 'x_tax'
          mapping :shipping, 'x_freight'
          mapping :test_request, 'x_test_request' # true or false, or 0 or 1 [not required to send one, defaults to false]
          
          # this one is necessary for the notify url to be able to parse its information later!
          def invoice number
            add_field 'x_invoice_num', number
          end
          
          def billing_address options # allows us to combine the addresses, just in case they use address2
            for setting in [:city, :state, :zip, :country] do
              add_field 'x_' + setting.to_s, options[setting]
            end
            add_field 'x_address', (options[:address].to_s + ' ' + options[:address2].to_s).strip
          end
          
          # displays tax as a line item, so they can see it.
          def add_tax_as_line_item
            raise unless @fields['x_tax']
            add_line_item :name => 'Total Tax', :quantity => 1, :unit_price => @fields['x_tax'], :tax => 0, :name => 'Tax'
          end
          
          # displays shipping as a line item, so they can see it
          def add_shipping_as_line_item extra_options = {}
            raise unless @fields['x_freight']
            add_line_item extra_options.merge({:name => 'Shipping Cost', :quantity => 1, :unit_price => @fields['x_freight'], :line_title => 'Shipping'})
          end
          
          # add shipping in the same format as the normal address is added
          def ship_to_address options
            for setting in [:first_name, :last_name, :company, :address, :city, :state, :zip, :country] do
              if options[setting] then
                add_field 'x_ship_to_' + setting.to_s, options[setting]
              end
            end
          end
          # these untested , and control the look of the payment page:)
          # note you can include a css header in descriptors, etc.
          mapping :color_link, 'x_color_link'
          mapping :color_text, 'x_color_text'
          mapping :logo_url, 'x_logo_url'
          mapping :background_url, 'x_background_url' # background image url for the page
          mapping :payment_header, 'x_header_html_payment_form'
          mapping :payment_footer, 'x_footer_html_payment_form'
          
          # for this to work you must have also passed in an email for the purchaser
          # NOTE there are more that could be added here--email body, etc.
          def do_email_customer_from_authorizes_side
            add_field 'x_email_customer', 'TRUE'
          end

          # could ensure the .00 format here, if desired
          # TODO check teh overflow, check a description with the badness in it (and badness everywhere)
          def add_line_item options
            raise 'no name' unless options[:name]
            if @line_item_count == 30 # then add a note that we are not showing at least one -- AN doesn't display more than 30 or so
              @verbatim_fields[-1][0].gsub! />([^>]*)<\|>[YN]$/, ($1[0..230] + ' + more unshown items after this one.')[0..254]
            end
            
            name = options[:name]
            quantity = options[:quantity] || 1
            line_title = options[:line_title] || ('Item ' + (@line_item_count+1).to_s) # left most field
            unit_price = options[:unit_price] || 0 # could check if AN accepts it without a unit_price
            tax_value = options[:tax_value] # takes Y or N or true, false, 0/1
            
            # sanitization, in case they include a reserved word here, follow guidelines
            # they ignore the sanitized_short_name, anyway [though maybe it gets set within AN somewhere, maybe]
            sanitized_short_name = name[0..31].gsub(/\s*-\s+/, '-').gsub(/\(|\)"/, ' ') # have no idea why, but if you put a  field value of T1000 - Lt. Blue Grey - Youth (17") it chokes.  This to avoid that at all costs.
            raise 'cannot pass in dollar sign' if unit_price.to_s.include? '$'
            unit_price = unit_price.to_f
            raise 'must have positive or 0 unit price' if unit_price < 0
            name = name[0..255] # wonder if this errs if it lops an escape sequence in half
            # note I don't [yet] have h here
            # I think these are the only ones that can mess it up
            name = name.gsub('<', "&lt;").gsub('>', '&gt;').gsub('"', '&quot;')
            sanitized_short_name = sanitized_short_name.gsub('<', "&lt;").gsub('>', '&gt;').gsub('"', '&quot;')
            add_verbatim_field "x_line_item", "#{line_title}<|>#{sanitized_short_name}<|>#{name}<|>#{quantity}<|>#{unit_price}<|>#{tax_value}"
            #<input id="x_line_item" name="x_line_item" type="hidden" value="Shipping\<|\>Shipping Cost<|>Shipping Cost<|>1<|>0<|>Y" />
            @line_item_count += 1
          end
            
          # if you call this it will e-mail to this email a copy of a receipt after
          # successful, from authorize.net
          def email_merchant_from_authorizes_side to_this_email
            add_field 'x_email_merchant', to_this_email
          end
          
          # Note.  You MUST call this for it to work.
          def setup_hash options
            raise unless options[:transaction_key] # TODO could ask if these should all be options, or...add should add another call in there :)
            raise unless options[:order_timestamp]
            amount = @fields['x_amount']
            raise 'odd -- non digit number!' unless amount.to_s =~ /\d/
            data = "#{@fields['x_login']}^#{@fields['x_fp_sequence']}^#{options[:order_timestamp].to_i}^#{amount}^#{@fields['x_currency_code']}"
            hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('md5'), options[:transaction_key], data)
            add_field 'x_fp_hash', hmac
            add_field 'x_fp_timestamp', options[:order_timestamp].to_i
          end
# TODO force tax
          # TODO ask if I should name mine as special or what not :)
          # Note that you should call #invoice as well, for the response_url to work
          def initialize(order, account, options = {})
            super
            raise 'missing parameter' unless order and account and options[:amount]
            add_field('x_type', 'AUTH_CAPTURE') # the only one we deal with, for now.  Not refunds or anything else, currently.
            add_field 'x_show_form', 'PAYMENT_FORM'
            add_field 'x_relay_response', 'TRUE'
            add_field 'x_duplicate_window', '28800' # large duplicate window.
            add_field 'x_currency_code', currency_code
          	add_field 'x_version' , '3.1' # version from docs
          	@line_item_count = 0
          	@verbatim_fields = []
            
          end
          
          
          def add_verbatim_field(name, value)
            return if name.blank? || value.blank?
            @verbatim_fields << [name, value]
          end
          
          def verbatim_fields
            @verbatim_fields
          end
          
          def self.payment_form_fields(order, account, options = {}, &proc)
            raise ArgumentError, "Missing block" unless block_given?

            integration_module = ActiveMerchant::Billing::Integrations.const_get(Inflector.classify("#{options.delete(:service)}"))

            result = "\n"

            service_class = integration_module.const_get('Helper')
            service = service_class.new(order, account, options)
            yield service
            result << service.form_fields.collect do |field, value|
              ActionView::Helpers::FormTagHelper.hidden_field_tag(field, value)
            end.join("\n")
            result << "\n"
            result << '</form>' 
            result
          end
          
        
        end
      end
    end
  end
end



module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module ActionViewHelper
        
# temporary holder that is modified to work with AN SIM
=begin
# example 

    payment_service_for('44','8wd65QS', :service => :authorize_net_sim,  :amount => 157.0){|service|

       service.setup_hash :transaction_key => '8CP6zJ7uD875J6tY',
           :order_timestamp => 1206836763
       service.customer_id 8
       service.customer :first_name => 'g',
                          :last_name => 'g',
                          :email => 'g@g.com',
                          :phone => '3'
      service.billing_address :zip => 'g',
                      :country => 'United States of America',
                      :address => 'g'
      
      service.ship_to_address :first_name => 'g',
                               :last_name => 'g',
                               :city => '',
                               :address => 'g',
                               :address2 => '',
#                               :state => address.state,
                               :country => 'United States of America',
                               :zip => 'g'
                               
      service.invoice "516428355"
      service.notify_url "http://t/authorize_net_sim/payment_received_notification_sub_step"
      service.payment_header 'MyFavoritePal'
      service.add_line_item :name => 'beauty2 - ayoyo', :quantity => 1, :unit_price => 0
      service.test_request 'true'
      service.shipping '25.0'
      service.add_shipping_as_line_item
      }

Another example, from real code:
<form action="https://secure.authorize.net/gateway/transact.dll" method='POST'>
<% payment_fields_authorize_net_sim_for(cart.id, Preference.get_value('cc_login'), :service => :authorize_net_sim,  :amount => cart.total){|service|

 address = cart.billing_address

  service.setup_hash :transaction_key => Preference.get_value('cc_pass'),
      :order_timestamp => cart.created_on
  service.customer_id cart.order_user.id
  service.customer :first_name => address.first_name,
                     :last_name => address.last_name,
                     :phone => address.telephone,
                     :email => cart.order_user.email_address
  service.billing_address :city => address.city,
                            :address => address.address,
                            :address2 => '',
                            :state => address.state,
                            :country => address.country.name,
                            :zip => address.zip

   # this next one must be called for the return_url to be able to parse its info
   service.invoice cart.order_number # invoice -- different than id
   service.shipping cart.shipping_cost
   service.tax cart.tax
   service.notify_url url_for(:only_path => false, :controller => :authorize_net_sim, :action => :payment_received_notification_sub_step)

   # now ANS specific one

   shipping = cart.shipping_address
   service.test_request 'true' if Preference.find_by_name('store_test_transactions').is_true? 
  
   service.ship_to_address  :first_name => shipping.first_name,
							:last_name => shipping.last_name,
							:city => address.city,
                            :address => address.address,
#                            :address2 => '',
                            :state => address.state,
                            :country => address.country.name,
                            :zip => address.zip

   service.payment_header Preference.get_value('store_name')
   taxable = cart.tax > 0 ? 'Y' : 'N'
   taxable = 'Y'
   service.add_tax_as_line_item if cart.tax > 0
   service.add_shipping_as_line_item :tax_value => taxable
   cart.order_line_items.each do |oli|
       unless oli.item # add word promo for discounts
		    oli.name = oli.name + ' (Promo) -- $' + oli.price.to_s + ' off'
			oli.price = 0
		end
		service.add_line_item :name => oli.name, :taxed => taxable, :unit_price => oli.price, :quantity => oli.quantity
	end
} %>
</form>
=end
        def payment_fields_authorize_net_sim_for(order, account, options = {}, &proc)
          raise ArgumentError, "Missing block" unless block_given?

          integration_module = ActiveMerchant::Billing::Integrations.const_get(Inflector.classify("#{options.delete(:service)}"))

          result = "\n"
          
          service_class = integration_module.const_get('Helper')
          service = service_class.new(order, account, options)
          yield service
          result << service.form_fields.collect do |field, value|
              hidden_field_tag(field, value)
            end.join("\n")
          result << service.verbatim_fields.collect do |field, value|
              "<input id=\"#{h(field)}\" name=\"#{h(field)}\" type=\"hidden\" value=\"#{value}\" />"
          end.join("\n")
          result << "\n"
          concat(result, proc.binding)
        end
        
        # same as payment_service_for, cept uses the above
        def payment_service_authorize_net_sim_for(order, account, options = {}, &proc)
          raise ArgumentError, "Missing block" unless block_given?

          integration_module = ActiveMerchant::Billing::Integrations.const_get(Inflector.classify("#{options.delete(:service)}"))

          concat(form_tag(integration_module.service_url, options.delete(:html) || {}), proc.binding)
          result = "\n"
          
          service_class = integration_module.const_get('Helper')
          service = service_class.new(order, account, options)
          yield service
          
          payment_fields_for order, account, options, &proc
          result << "\n"
          result << '</form>' 
          concat(result, proc.binding)
        end
        
        
      end
    end
  end
end


=begin

This is an example controller to parse the response manually
MD5_HASH_SET_IN_AUTHORIZE_NET = ''
class AuthorizeNetSimController < ApplicationController

  def payment_received_notification_sub_step
    passed = params['x_response_code'].to_i == 1
    
    order = Order.find_by_order_number params['x_invoice_num'],
            :include => :shipping_address
    unless order
      # this has never happened
            @message = 'Error--unable to find your transaction!  Please contact us directly.'
            return render :partial => '/store/authorize_net_sim_payment_response'
    end

    # todo integrate AVS (?) CVV
    # todo double check if they changed any address information (just in case the user didn't set it up for that to be unchangeable, which would, of course, be much better)
    if order.total != params['x_amount'].to_f
      logger.error "ack authorize net sim said they paid for #{params['x_amount']} and it should have been #{order.total}!"
      passed = false
    end
    
    existing_order = Order.find_by_auth_transaction_id(params['x_trans_id'])
    
    if existing_order
      logger.error "odd -- authorize.net SIM got a duplicate transaction!" # still allow it to pass--why not?
    end
    
    md5_hash_check = Digest::MD5.hexdigest(MD5_HASH_SET_IN_AUTHORIZE_NET + Preference.get_value('cc_login') + params['x_trans_id'] + params['x_amount'])
    
    if md5_hash_check.upcase != params['x_MD5_Hash']
      passed = false
      logger.error "ALERT POSSIBLE FRAUD ATTEMPT either that or you haven't setup your md5 hash setting in #{__FILE__} because a transaction came back from authorize.net with the wrong hash value--rejecting!"
    end
    
    order.auth_transaction_id = params['x_trans_id'] # they give us this
    # at this point passed tells us whether it worked or not
    if passed
      @message = 'passed!'
    else
      @message = 'failed'
    end  
   
   
   here's the rest of my own code -- none of it matters too much.
   It should be noted that we pass them back an html page, which is hosted ON THEIR WEB SITe
   This means that relative links to things like stylesheets won't work.
   To avoid this as a problem, I just had the rendered page redirect them back to my site to a 'normal' page
   
   <head>
   	<!-- note that it redirects automatically for most, so they'll never really see this page -->
   	<% if @order and @order.order_status_code_id == 5 # then it was successful, so forward them on the the status page %>
   		<SCRIPT LANGUAGE="JavaScript">
   		  window.location="<%= url_for(:only_path => false, :controller => :store, :action => :finish_order) %>";
   		</script>
   	<% end %>
   </head>
   
   
    # the rest of my own code--though this stuff will be application dependent   
    # could refactor this with paypal (combine) 
    if passed
         order.order_status_code_id = 5 # passed
         order.new_notes = "Your order paid through Authorize.net SIM.  Ready to ship."
         # Set completed
         order.cleanup_successful
         # Send success message
         begin
           order.deliver_receipt # sends the emails right
         rescue => e
           logger.error("FAILED TO SEND THE CONFIRM EMAIL")
         end
         order.save
    else
         message = "FRAUD ALERT -- please investigate." + params.inspect
         log.error params.inspect + " seemed to have failed authorize.net sim"
         order.order_status_code_id = 3
         order.new_notes = message
         order.cleanup_failed(message)
         # Send failed message
         begin
           order.deliver_failed 
         rescue => e
           logger.error("FAILED TO SEND THE CONFIRM EMAIL")
         end
         order.save
    end
    
    render :partial => 'store/authorize_net_sim_payment_response'
  end
=end