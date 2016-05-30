module ActiveAdmin
  class OrderClause
    alias_method :initialize_original, :initialize
    def initialize(clause)
      @@postgres ||= ActiveRecord::Base.connection.instance_of?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
      initialize_original(clause)
    end

    alias_method :to_sql_original, :to_sql
    def to_sql(active_admin_config)
      sql = to_sql_original(active_admin_config)
      sql = sql + ' NULLS LAST' if @order == 'desc' and @@postgres
      sql = sql + ' NULLS FIRST' if @order == 'asc' and @@postgres
      sql
    end
  end
end
