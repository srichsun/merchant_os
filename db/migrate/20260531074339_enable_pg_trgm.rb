class EnablePgTrgm < ActiveRecord::Migration[8.1]
  # Trigram matching powers partial / Chinese substring product search
  def change
    enable_extension "pg_trgm"
  end
end
