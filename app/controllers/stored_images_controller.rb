class StoredImagesController < ApplicationController
  before_action :set_stored_image, only: [:show, :update, :destroy]

  # GET /stored_images
  def index
    @stored_images = StoredImage.all

    if is_admin?
      render json: {
        images: {
          verified: @stored_images.where(verified: true),
          unverified: @stored_images.where(verified: false),
        }
      }
    else
      render json: {
        images: {
          verified: @stored_images.where(verified: true)
        },
      }, include: [user: {only: :username}]
    end
  end

  # GET /stored_images/:id
  def show
    if is_admin?
      render json: {
        image: @stored_image,
      }
    elsif verify_login
      if @stored_image.verified || @stored_image.user == verify_login
        render json: {
          image: @stored_image,
        }, include: [user: {only: :username}]
      else
        render json: {
          errors: ['May only view own unverified image'],
        }
      end
    else
      render json: {
        errors: ['Must be logged in'],
      }
    end
  end

  # POST /stored_images
  def create
    @stored_image = StoredImage.new(stored_image_params)

    if @stored_image.save
      render json: @stored_image, status: :created, location: @stored_image
    else
      render json: @stored_image.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /stored_images/1
  def update
    if @stored_image.update(stored_image_params)
      render json: @stored_image
    else
      render json: @stored_image.errors, status: :unprocessable_entity
    end
  end

  # DELETE /stored_images/1
  def destroy
    @stored_image.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_stored_image
      @stored_image = StoredImage.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def stored_image_params
      params.require(:stored_image).permit(:url)
    end
end
