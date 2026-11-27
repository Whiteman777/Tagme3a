"""reviewer-learned aliases and deterministic vector matching

Revision ID: 0003
Revises: 0002
Create Date: 2026-11-27
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0003"
down_revision: str | None = "0002"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _pgvector_available() -> bool:
    """The vector index is opportunistic; rapidfuzz works without it."""
    bind = op.get_bind()
    if bind.dialect.name != "postgresql":
        return False
    return bool(
        bind.execute(
            sa.text("SELECT 1 FROM pg_available_extensions WHERE name = 'vector'")
        ).scalar()
    )


def upgrade() -> None:
    op.create_table(
        "product_aliases",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("product_id", sa.Integer(), nullable=False),
        sa.Column("alias", sa.String(length=300), nullable=False),
        sa.Column("normalized", sa.String(length=300), nullable=False),
        sa.Column("source", sa.String(length=24), server_default="manual", nullable=False),
        sa.Column("created_by", sa.Integer(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["created_by"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "product_id", "normalized", name="uq_product_alias_product_normalized"
        ),
    )
    op.create_index(
        "ix_product_aliases_product_id", "product_aliases", ["product_id"], unique=False
    )
    op.create_index(
        "ix_product_aliases_normalized", "product_aliases", ["normalized"], unique=False
    )

    op.add_column(
        "staging_listings", sa.Column("suggested_product_id", sa.Integer(), nullable=True)
    )
    op.add_column(
        "staging_listings",
        sa.Column("suggestion_confidence", sa.Numeric(precision=5, scale=4), nullable=True),
    )
    op.add_column(
        "staging_listings", sa.Column("suggestion_reason", sa.String(length=64), nullable=True)
    )
    op.create_foreign_key(
        "fk_staging_suggested_product",
        "staging_listings",
        "products",
        ["suggested_product_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index(
        "ix_staging_listings_suggested_product_id",
        "staging_listings",
        ["suggested_product_id"],
        unique=False,
    )

    if _pgvector_available():
        op.execute("CREATE EXTENSION IF NOT EXISTS vector")
        op.execute(
            """
            CREATE TABLE IF NOT EXISTS product_embeddings (
                product_id INTEGER PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
                embedding vector(256) NOT NULL,
                updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
            )
            """
        )


def downgrade() -> None:
    if _pgvector_available():
        op.execute("DROP TABLE IF EXISTS product_embeddings")

    op.drop_index(
        "ix_staging_listings_suggested_product_id", table_name="staging_listings"
    )
    op.drop_constraint(
        "fk_staging_suggested_product", "staging_listings", type_="foreignkey"
    )
    op.drop_column("staging_listings", "suggestion_reason")
    op.drop_column("staging_listings", "suggestion_confidence")
    op.drop_column("staging_listings", "suggested_product_id")

    op.drop_index("ix_product_aliases_normalized", table_name="product_aliases")
    op.drop_index("ix_product_aliases_product_id", table_name="product_aliases")
    op.drop_table("product_aliases")
