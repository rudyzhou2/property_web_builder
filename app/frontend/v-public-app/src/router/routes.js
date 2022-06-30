const routes = [

  {
    path: '/',
    component: () => import('~/v-public-app/src/layouts/PublicLayout.vue'),
    children: [
      {
        path: '',
        name: 'rDefaultLocaleHomePage',
        component: () => import("~/v-public-app/src/components/PageContainer.vue"),
      },
      {
        path: '/:publicLocale',
        name: 'rLocaleHomePage',
        component: () => import("~/v-public-app/src/components/EmptyContainer.vue"),
        children: [
          {
            path: '',
            name: 'rLocaleHomePage',
            component: () => import("~/v-public-app/src/components/PageContainer.vue"),
          },
          {
            path: ':pageSlug',
            name: "rPublicPage",
            component: () => import("~/v-public-app/src/components/PageContainer.vue"),
          },
        ]
      },
    ]
  },

  // // Always leave this as last one,
  // // but you can also remove it
  // {
  //   path: "/:catchAll(.*)*",
  //   component: () => import("pages/Error404.vue"),
  // },
]

export default routes