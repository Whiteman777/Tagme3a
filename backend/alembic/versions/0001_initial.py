"""initial catalog + users schema

Revision ID: 0001
Revises:
Create Date: 2026-11-21
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("firebase_uid", sa.String(length=128), nullable=False),
        sa.Column("email", sa.String(length=320), nullable=True),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.Column("display_name", sa.String(length=120), nullable=True),
        sa.Column("photo_url", sa.String(length=1024), nullable=True),
        sa.Column(
            "role",
            sa.Enum("user", "reviewer", "admin", name="userrole", native_enum=False),
            server_default="user",
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=False)
    op.create_index("ix_users_firebase_uid", "users", ["firebase_uid"], unique=True)
    op.create_index("ix_users_role", "users", ["role"], unique=False)

    op.create_table(
        "merchants",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("key", sa.String(length=64), nullable=False),
        sa.Column("name", sa.String(length=160), nullable=False),
        sa.Column("name_ar", sa.String(length=160), nullable=True),
        sa.Column("base_url", sa.String(length=1024), nullable=False),
        sa.Column("adapter_key", sa.String(length=64), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_merchants_key", "merchants", ["key"], unique=True)

    op.create_table(
        "products",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("slug", sa.String(length=255), nullable=False),
        sa.Column(
            "category",
            sa.Enum(
                "cpu", "gpu", "motherboard", "ram", "psu", "case", "cooler",
                "storage", "laptop", "peripheral",
                name="productcategory", native_enum=False,
            ),
            nullable=False,
        ),
        sa.Column("brand", sa.String(length=120), nullable=False),
        sa.Column("model", sa.String(length=255), nullable=False),
        sa.Column("name", sa.String(length=400), nullable=False),
        sa.Column("name_ar", sa.String(length=400), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("image_url", sa.String(length=1024), nullable=True),
        sa.Column("specs", sa.JSON(), server_default=sa.text("'{}'"), nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_products_category", "products", ["category"], unique=False)
    op.create_index("ix_products_category_brand", "products", ["category", "brand"], unique=False)
    op.create_index("ix_products_brand", "products", ["brand"], unique=False)
    op.create_index("ix_products_slug", "products", ["slug"], unique=True)

    op.create_table(
        "offers",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("product_id", sa.Integer(), nullable=False),
        sa.Column("merchant_id", sa.Integer(), nullable=False),
        sa.Column("url", sa.String(length=2048), nullable=False),
        sa.Column("price_egp", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("in_stock", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("match_confidence", sa.Numeric(precision=5, scale=4), nullable=True),
        sa.Column(
            "first_seen_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "last_seen_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["merchant_id"], ["merchants.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("product_id", "merchant_id", name="uq_offers_product_merchant"),
    )
    op.create_index("ix_offers_in_stock", "offers", ["in_stock"], unique=False)
    op.create_index("ix_offers_last_seen_at", "offers", ["last_seen_at"], unique=False)
    op.create_index("ix_offers_merchant_id", "offers", ["merchant_id"], unique=False)
    op.create_index("ix_offers_price_egp", "offers", ["price_egp"], unique=False)
    op.create_index("ix_offers_product_id", "offers", ["product_id"], unique=False)

    op.create_table(
        "price_history",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("offer_id", sa.Integer(), nullable=False),
        sa.Column("price_egp", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("in_stock", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("source", sa.String(length=64), server_default="scraper", nullable=False),
        sa.Column(
            "captured_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.ForeignKeyConstraint(["offer_id"], ["offers.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_price_history_captured_at", "price_history", ["captured_at"], unique=False)
    op.create_index(
        "ix_price_history_offer_time", "price_history", ["offer_id", "captured_at"], unique=False
    )
    op.create_index("ix_price_history_offer_id", "price_history", ["offer_id"], unique=False)


def downgrade() -> None:
    op.drop_table("price_history")
    op.drop_table("offers")
    op.drop_table("products")
    op.drop_table("merchants")
    op.drop_table("users")
