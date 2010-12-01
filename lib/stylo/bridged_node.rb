class Stylo::BridgedNode < Stylo::Node

  key :bridged_class_name, String
  key :bridged_id, Integer

  def bridged_item
    self.bridged_class_name.constantize.send(:find, self.bridged_id)
  end

  def container?
    false
  end

  def bridged?
    true
  end
end





