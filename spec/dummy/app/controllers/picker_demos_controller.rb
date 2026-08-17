class PickerDemosController < ApplicationController
  def show
    @widget = Widget.first_or_create!(name: "Picker demo")
  end
end
