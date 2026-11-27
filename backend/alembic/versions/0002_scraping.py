"""scraping snapshots, staging listings and run health

Revision ID: 0002
Revises: 0001
Create Date: 2026-11-27
"""

from collections.abc import Sequence

import sqlalchemy as sa

from alembic import op

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "raw_snapshots",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("merchant_id", sa.Integer(), nullable=False),
        sa.Column("url", sa.String(length=2048), nullable=False),
        sa.Column("checksum", sa.String(length=64), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("status_code", sa.Integer(), nullable=True),
        sa.Column(
            "parse_status",
            sa.Enum("pending", "parsed", "failed", name="parsestatus", native_enum=False),
            server_default="pending",
            nullable=False,
        ),
        sa.Column(
            "fetched_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("parsed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("attempts", sa.Integer(), server_default="0", nullable=False),
        sa.Column("error", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["merchant_id"], ["merchants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "merchant_id", "url", "checksum", name="uq_raw_snapshot_merchant_url_checksum"
        ),
    )
    op.create_index("ix_raw_snapshots_merchant_id", "raw_snapshots", ["merchant_id"], unique=False)
    op.create_index(
        "ix_raw_snapshots_parse_status", "raw_snapshots", ["parse_status"], unique=False
    )
    op.create_index(
        "ix_raw_snapshot_merchant_fetched",
        "raw_snapshots",
        ["merchant_id", "fetched_at"],
        unique=False,
    )

    op.create_table(
        "staging_listings",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("raw_snapshot_id", sa.Integer(), nullable=False),
        sa.Column("merchant_id", sa.Integer(), nullable=False),
        sa.Column("external_id", sa.String(length=255), nullable=False),
        sa.Column("raw_title", sa.String(length=500), nullable=False),
        sa.Column("normalized_name", sa.String(length=500), nullable=True),
        sa.Column("brand", sa.String(length=120), nullable=True),
        sa.Column("model", sa.String(length=255), nullable=True),
        sa.Column(
            "category",
            sa.Enum(
                "cpu",
                "gpu",
                "motherboard",
                "ram",
                "psu",
                "case",
                "cooler",
                "storage",
                "laptop",
                "peripheral",
                name="productcategory",
                native_enum=False,
            ),
            nullable=True,
        ),
        sa.Column("price_egp", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("currency", sa.String(length=8), server_default="EGP", nullable=False),
        sa.Column("in_stock", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        sa.Column("url", sa.String(length=2048), nullable=False),
        sa.Column(
            "match_status",
            sa.Enum(
                "unmatched",
                "auto_matched",
                "matched",
                "rejected",
                name="matchstatus",
                native_enum=False,
            ),
            server_default="unmatched",
            nullable=False,
        ),
        sa.Column("match_confidence", sa.Numeric(precision=5, scale=4), nullable=True),
        sa.Column("product_id", sa.Integer(), nullable=True),
        sa.Column("reviewed_by", sa.Integer(), nullable=True),
        sa.Column("reviewed_at", sa.DateTime(timezone=True), nullable=True),
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
        sa.ForeignKeyConstraint(["product_id"], ["products.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["raw_snapshot_id"], ["raw_snapshots.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["reviewed_by"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("merchant_id", "external_id", name="uq_staging_merchant_external"),
    )
    op.create_index(
        "ix_staging_listings_raw_snapshot_id",
        "staging_listings",
        ["raw_snapshot_id"],
        unique=False,
    )
    op.create_index(
        "ix_staging_listings_merchant_id", "staging_listings", ["merchant_id"], unique=False
    )
    op.create_index(
        "ix_staging_listings_match_status", "staging_listings", ["match_status"], unique=False
    )
    op.create_index(
        "ix_staging_listings_product_id", "staging_listings", ["product_id"], unique=False
    )
    op.create_index(
        "ix_staging_merchant_status",
        "staging_listings",
        ["merchant_id", "match_status"],
        unique=False,
    )

    op.create_table(
        "scraper_runs",
        sa.Column("id", sa.Integer(), autoincrement=True, nullable=False),
        sa.Column("merchant_id", sa.Integer(), nullable=False),
        sa.Column(
            "started_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("finished_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "status",
            sa.Enum("ok", "partial", "failed", name="runstatus", native_enum=False),
            server_default="partial",
            nullable=False,
        ),
        sa.Column("listings_found", sa.Integer(), server_default="0", nullable=False),
        sa.Column("listings_parsed", sa.Integer(), server_default="0", nullable=False),
        sa.Column("snapshots_new", sa.Integer(), server_default="0", nullable=False),
        sa.Column("duration_ms", sa.Integer(), nullable=True),
        sa.Column("error", sa.Text(), nullable=True),
        sa.ForeignKeyConstraint(["merchant_id"], ["merchants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_scraper_runs_merchant_id", "scraper_runs", ["merchant_id"], unique=False)
    op.create_index("ix_scraper_runs_status", "scraper_runs", ["status"], unique=False)
    op.create_index(
        "ix_scraper_run_merchant_started",
        "scraper_runs",
        ["merchant_id", "started_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_table("scraper_runs")
    op.drop_table("staging_listings")
    op.drop_table("raw_snapshots")
