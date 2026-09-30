import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

const blog = defineCollection({
	// Load Markdown and MDX files in the `src/content/blog/` directory.
	loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
	// Type-check frontmatter using a schema
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			// Transform string to Date object
			pubDate: z.coerce.date(),
			updatedDate: z.coerce.date().optional(),
			heroImage: z.optional(image()),
			tags: z.array(z.string()).default([]),
			featured: z.boolean().default(false),
		}),
});

const projects = defineCollection({
	loader: glob({ base: './src/content/projects', pattern: '**/*.{md,mdx}' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			category: z.string(), // e.g., 'macOS 앱', '데스크톱 도구', '모바일 앱'
			tags: z.array(z.string()).default([]),
			badges: z.array(z.string()).default([]),
			pubDate: z.coerce.date(),
			githubUrl: z.string().optional(),
			demoUrl: z.string().optional(),
			featured: z.boolean().default(false),
			order: z.number().default(99),
			heroImage: z.optional(image()),
		}),
});

export const collections = { blog, projects };
