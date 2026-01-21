class CreateReviewAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :review_audit_logs do |t|
      t.references :story, null: false, foreign_key: true
      t.references :admin, null: false, foreign_key: { to_table: :users }
      t.string :action
      t.text :reason

      t.timestamps
    end
  end
end