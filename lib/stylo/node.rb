class Stylo::Node
  cattr_accessor :stylo_class
  include MongoMapper::Document
  key :node_type, String
  key :category, String, :index => true
  key :description, String, :default => ''
  key :search_terms, Array, :index => true

  key :parents, Array, :index => true
  key :parent_id, BSON::ObjectId
  key :child_count, Integer, :default => 0
  key :path_names, Array

  timestamps!

  before_create :build_path_names
  before_destroy :remove_from_hierarchy
  before_save :build_search_terms
  before_update :delete_path_names_if_category_changed

  def parent_categories
    @parent_categories ||= self.stylo_class.node_class.where('_id' => {'$in' => parents}).all
  end

  def parent
    @parent ||= self.stylo_class.node_class.find(self.parent_id)
  end

  def children
    self.stylo_class.node_class.where(:parent_id => id).all
  end

  def all_leaves
    self.stylo_class.bridged_node_class.where(:parents => id).all
  end

  def leaves(limit = nil)
    if limit
      self.stylo_class.bridged_node_class.where(:parents => id).limit(limit).all
    else
      self.all_leaves
    end
  end

  def remove_from_hierarchy
    Stylo::Ontology.remove_from_hierarchy(self)
  end

  def build_search_terms
    if description_changed?
      self.search_terms = self.description.downcase.split(' ').uniq if self.description
    end
  end

  def container?
    true
  end

  alias_method :old_path_names, :path_names

  def path_names
    build_path_names if old_path_names.empty?
    old_path_names
  end

  def path
    @path ||= self.path_names.join(' / ')
  end


  def build_path_names
    if self.parents
      if self.parents.size > 1
        self.path_names = self.stylo_class.node_class.where('_id' => {'$in' => parents[1..-1]}).fields(:category).all.collect { |x| x.category }.compact << self.category
      else
        self.path_names = [self.category].compact
      end
    end
  end

  def delete_path_names_if_category_changed
    if category_changed?
      path_names[-1] = category
      self.collection.update({'parents' => self.id}, {'$set' => {'path_names' => []}}, :multi => true)
    end
  end
end




