export function formatPrice(price: number): string {
  return new Intl.NumberFormat('fr-FR', {
      style: 'currency',
          currency: 'EUR',
            }).format(price)
            }

            export function formatDate(date: string | Date): string {
              return new Intl.DateTimeFormat('fr-FR', {
                  day: '2-digit',
                      month: 'long',
                          year: 'numeric',
                            }).format(new Date(date))
                            }

                            export function generateSlug(text: string): string {
                              return text
                                  .toLowerCase()
                                      .normalize('NFD')
                                          .replace(/[\u0300-\u036f]/g, '')
                                              .replace(/[^a-z0-9]+/g, '-')
                                                  .replace(/^-+|-+$/g, '')
                                                  }

                                                  export function truncate(text: string, length: number): string {
                                                    if (text.length <= length) return text
                                                      return text.slice(0, length) + '...'
                                                      }
