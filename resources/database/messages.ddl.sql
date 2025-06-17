CREATE TABLE public.messages (
	id bpchar(36) NOT NULL,
	"content" text NULL,
	created_at timestamp NULL,
	created_by varchar(128) NULL,
	CONSTRAINT messages_pk PRIMARY KEY (id)
);